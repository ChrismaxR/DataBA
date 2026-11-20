# Boxmodel: belasting, achterstand en wachttijd per behandelkamer per scenario
## Rekent per scenario (src/generateScripts/scenarioDefinities.R) en per dag
## de verwachte stromen door het ziekenhuis door, rechtstreeks uit de
## parameters en zonder de simulatie te draaien. Bedoeld als snelle screening:
## welke kamers knellen, wanneer, en hoeveel capaciteit is nodig?
##
##   rho         = werklast / beschikbare capaciteit
##               = bezoeken x gem. behandelduur x servicefactor
##                 / (aantal kamers x minuten per werkdag)
##   achterstand = voorraad onafgemaakt werk (mass balance over de dagen)
##   wachttijd   = benadering Allen-Cunneen (G/G/c), alleen bij rho < 1
##
## Niet gemodelleerd: bandbreedtes over runs (daarvoor de simulatie) en de
## precieze dynamiek van doorschuivende behandelingen.
## Uitvoeren vanuit de projectroot.

library(dplyr)
library(purrr)
library(tidyr)
set.seed(42) # dit script bevat geen toeval; conventie voor entry scripts

source("src/generateScripts/simmerConfig.R")
source("src/generateScripts/scenarioDefinities.R")

# 0) Instellingen ----------

rho_doel <- 0.85 # gewenste maximale benutting (Fasering: 70-85%)
wachttijd_norm <- 30 # minuten; PLACEHOLDER voor "norm X" uit de README
behandelduur_cs2 <- exp(0.3^2) - 1 # kwadr. variatiecoëff. lognormaal, sdlog 0.3
simulatie_dagen <- seq(0, simDays - 1)

# 1) Parameters die (nog) alleen in simmerImplementatie.R staan ----------
# LET OP: kopie van resource_durations, aandoening_route en de maak_traject()-
# aanroepen uit simmerImplementatie.R. Synchroon houden tot deze naar
# simmerConfig.R verhuizen.

## Min/max behandelduur (minuten) per kamer; de simulatie trekt lognormaal
## rond het gemiddelde hiervan.
behandelduur_per_kamer <- tibble::tribble(
  ~behandelkamerId , ~minDuur , ~maxDuur ,
   1L              ,        5 ,       10 ,
   2L              ,        9 ,       15 ,
   3L              ,        9 ,       15 ,
   4L              ,       11 ,       17 ,
   5L              ,       11 ,       17 ,
   6L              ,       15 ,       20 ,
   7L              ,       15 ,       20 ,
   8L              ,       25 ,       35 ,
   9L              ,       25 ,       35 ,
  10L              ,       25 ,       35 ,
  11L              ,       45 ,       60 ,
  12L              ,       45 ,       60 ,
  13L              ,       55 ,       75 ,
  14L              ,       55 ,       75 ,
  15L              ,       55 ,       75 ,
  16L              ,       60 ,       80 ,
  17L              ,       60 ,       80 ,
  18L              ,       60 ,       80 ,
  19L              ,       60 ,       80 ,
  20L              ,       60 ,       80
) |>
  mutate(gemBehandelduur = (minDuur + maxDuur) / 2)

## Route (trajectletter) per aandoening
route_per_aandoening <- tibble::tibble(
  aandoeningId = 1:33,
  route = c(
    "A",
    "A",
    "A",
    "B",
    "B",
    "B",
    "B",
    "C",
    "C",
    "D",
    "E",
    "E",
    "E",
    "F",
    "F",
    "F",
    "F",
    "G",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "L",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S"
  )
)

## Diagnose- en behandelkamer per route
kamers_per_route <- tibble::tribble(
  ~route , ~diagnoseKamerId , ~behandelKamerId ,
  "A"    , 2L               ,  8L              ,
  "B"    , 2L               , 10L              ,
  "C"    , 2L               , 18L              ,
  "D"    , 2L               , 14L              ,
  "E"    , 2L               ,  9L              ,
  "F"    , 3L               , 11L              ,
  "G"    , 3L               , 10L              ,
  "H"    , 3L               , 18L              ,
  "I"    , 3L               , 12L              ,
  "J"    , 3L               , 16L              ,
  "K"    , 4L               , 17L              ,
  "L"    , 7L               , 17L              ,
  "M"    , 7L               , 11L              ,
  "N"    , 7L               , 10L              ,
  "O"    , 7L               , 20L              ,
  "P"    , 5L               , 19L              ,
  "Q"    , 5L               , 10L              ,
  "R"    , 6L               , 10L              ,
  "S"    , 6L               , 13L
)

# 2) Afgeleide opzoektabellen (scenario-onafhankelijk) ----------

kamers <- tibble::as_tibble(resource_definitie) |>
  transmute(
    behandelkamerId = id,
    behandelkamerNaam = resourceName,
    behandelkamerType = resource_type
  ) |>
  left_join(behandelduur_per_kamer, by = "behandelkamerId")

receptie_id <- kamers$behandelkamerId[kamers$behandelkamerType == "Receptie"]

kamers_per_aandoening <- route_per_aandoening |>
  left_join(kamers_per_route, by = "route")

# 3) Instroom, routering en capaciteit per dag ----------

# Waarde uit een kwartaalschema die geldt op `dag` (gevectoriseerd over dagen)
schema_waarde_op_dag <- function(schema, kolom, dag) {
  schema[[kolom]][findInterval(dag, schema$dag_van)]
}

# Per dag: kwartaal, verwachte instroom en servicefactor.
# Instroom = Poisson-rate (per minuut) x lengte aankomstvenster (werkdag).
dag_instellingen <- function(par) {
  tibble(dag = simulatie_dagen) |>
    mutate(
      kwartaal = findInterval(dag, par$aankomst_schema$dag_van),
      instroomPerDag = schema_waarde_op_dag(par$aankomst_schema, "rate", dag) *
        workDayMinutes,
      serviceFactor = schema_waarde_op_dag(
        par$service_schema,
        "multiplier",
        dag
      )
    )
}

# Kans per aandoening per dag: basisgewicht plus de bellcurve-boost van elke
# epidemische golf (één golf met basisgewicht 1 = aandoeningBepaling() in
# simmerImplementatie.R)
aandoening_kansen <- function(par) {
  golf_boost <- par$epidemie_golven |>
    cross_join(tibble(dag = simulatie_dagen)) |>
    mutate(
      boost = (piekGewicht - 1) * exp(-0.5 * ((dag - piekDag) / sdDagen)^2)
    ) |>
    group_by(dag, aandoeningId) |>
    summarise(boost = sum(boost), .groups = "drop")

  expand_grid(
    dag = simulatie_dagen,
    aandoeningId = seq_along(par$aandoening_gewichten)
  ) |>
    mutate(basisGewicht = par$aandoening_gewichten[aandoeningId]) |>
    left_join(golf_boost, by = c("dag", "aandoeningId")) |>
    mutate(gewicht = basisGewicht + coalesce(boost, 0)) |>
    group_by(dag) |>
    mutate(kans = gewicht / sum(gewicht)) |>
    ungroup()
}

# Verwachte patiëntenstroom per dag per aandoening, met diagnose- en behandelkamer
patientstromen <- function(par, dagen) {
  aandoening_kansen(par) |>
    left_join(dagen, by = "dag") |>
    left_join(kamers_per_aandoening, by = "aandoeningId") |>
    transmute(
      dag,
      aandoeningId,
      diagnoseKamerId,
      behandelKamerId,
      bezoeken = instroomPerDag * kans
    )
}

# Verwachte bezoeken per kamer per dag: iedereen langs de receptie, daarna
# één diagnose- en één behandelkamer. Kamers zonder bezoek krijgen 0.
bezoeken_per_kamer <- function(stromen, dagen) {
  bezoeken <- bind_rows(
    dagen |>
      transmute(dag, behandelkamerId = receptie_id, bezoeken = instroomPerDag),
    stromen |> select(dag, behandelkamerId = diagnoseKamerId, bezoeken),
    stromen |> select(dag, behandelkamerId = behandelKamerId, bezoeken)
  ) |>
    group_by(dag, behandelkamerId) |>
    summarise(bezoekenPerDag = sum(bezoeken), .groups = "drop")

  expand_grid(
    dag = simulatie_dagen,
    behandelkamerId = kamers$behandelkamerId
  ) |>
    left_join(bezoeken, by = c("dag", "behandelkamerId")) |>
    mutate(bezoekenPerDag = coalesce(bezoekenPerDag, 0))
}

# Capaciteit per kamer per dag: basis uit resource_definitie, overschreven door
# de laatst ingegane wijziging uit capaciteit_schema (trapfunctie). Dit is het
# bedoelde gedrag; in de simulatie geldt een wijziging nu maar één dag.
capaciteit_per_dag <- function(par) {
  wijzigingen <- par$capaciteit_schema |>
    rename(wijzigingDag = dag)

  par$resource_definitie |>
    transmute(
      behandelkamerId = id,
      resourceName,
      basisCapaciteit = capacity
    ) |>
    cross_join(tibble(dag = simulatie_dagen)) |>
    left_join(
      wijzigingen,
      by = join_by(resourceName, closest(dag >= wijzigingDag))
    ) |>
    transmute(
      dag,
      behandelkamerId,
      basisCapaciteit,
      capaciteit = coalesce(nieuwe_cap, basisCapaciteit)
    )
}

# 4) Wachtrijtheorie ----------

# rho met nette randgevallen: geen capaciteit maar wel werk = Inf
bereken_rho <- function(werklast, beschikbaar) {
  case_when(
    beschikbaar > 0 ~ werklast / beschikbaar,
    werklast > 0 ~ Inf,
    TRUE ~ 0
  )
}

# Erlang C: kans dat een patiënt moet wachten in een M/M/c-systeem met
# c kamers en aangeboden belasting a (= lambda x behandelduur)
erlang_c <- function(c, a) {
  if (is.na(a) || c < 1 || a >= c) {
    return(NA_real_)
  }
  k <- 0:(c - 1)
  staart <- a^c / factorial(c) * c / (c - a)
  staart / (sum(a^k / factorial(k)) + staart)
}

# Gemiddelde wachttijd (minuten) in een G/G/c-systeem (Allen-Cunneen):
# M/M/c-wachttijd geschaald met de variabiliteit van aankomsten en behandeling
wachttijd_allen_cunneen <- function(lambda, behandelduur, c, ca2, cs2) {
  kans_wachten <- map2_dbl(c, lambda * behandelduur, erlang_c)
  kans_wachten / (c / behandelduur - lambda) * (ca2 + cs2) / 2
}

# Kwadr. variatiecoëff. van de vertrekstroom uit een kamer (benadering Whitt);
# bij overbelasting (rho >= 1) bepaalt de behandeling het vertrekpatroon
variatie_na_kamer <- function(ca2, rho, c, cs2) {
  r <- pmin(rho, 1)
  1 + (1 - r^2) * (ca2 - 1) + r^2 * (cs2 - 1) / sqrt(pmax(c, 1))
}

# Kwadr. variatiecoëff. na willekeurig splitsen met kans p
variatie_na_splitsing <- function(cd2, p) {
  p * cd2 + 1 - p
}

# Aankomstvariatie (ca2) per kamer per dag, de keten door:
# receptie (scenario-CV) -> diagnosekamers -> behandelkamers (gewogen  menging)
aankomstvariatie_per_kamer <- function(kamer_dag, stromen, ca2_receptie) {
  receptie <- kamer_dag |>
    filter(behandelkamerId == receptie_id) |>
    transmute(
      dag,
      behandelkamerId,
      ca2 = ca2_receptie,
      cd2Receptie = variatie_na_kamer(ca2, rho, capaciteit, behandelduur_cs2),
      instroom = bezoekenPerDag
    )

  diagnose <- kamer_dag |>
    filter(behandelkamerId %in% kamers_per_route$diagnoseKamerId) |>
    left_join(select(receptie, dag, cd2Receptie, instroom), by = "dag") |>
    mutate(
      aandeel = if_else(instroom > 0, bezoekenPerDag / instroom, 0),
      ca2 = variatie_na_splitsing(cd2Receptie, aandeel),
      cd2 = variatie_na_kamer(ca2, rho, capaciteit, behandelduur_cs2)
    )

  behandeling <- stromen |>
    group_by(dag, diagnoseKamerId, behandelKamerId) |>
    summarise(stroom = sum(bezoeken), .groups = "drop") |>
    left_join(
      diagnose |>
        select(
          dag,
          diagnoseKamerId = behandelkamerId,
          cd2,
          bezoekenDiagnose = bezoekenPerDag
        ),
      by = c("dag", "diagnoseKamerId")
    ) |>
    mutate(
      aandeel = if_else(bezoekenDiagnose > 0, stroom / bezoekenDiagnose, 0),
      ca2Deelstroom = variatie_na_splitsing(cd2, aandeel)
    ) |>
    group_by(dag, behandelkamerId = behandelKamerId) |>
    summarise(
      ca2 = if (sum(stroom) > 0) weighted.mean(ca2Deelstroom, stroom) else 1,
      .groups = "drop"
    )

  bind_rows(
    select(receptie, dag, behandelkamerId, ca2),
    select(diagnose, dag, behandelkamerId, ca2),
    behandeling
  )
}

# Achterstand (minuten werk) per dag: voorraad van gisteren + werklast -
# capaciteit, nooit negatief
bereken_achterstand <- function(netto_instroom) {
  accumulate(
    netto_instroom,
    \(voorraad, netto) max(0, voorraad + netto),
    .init = 0
  )[-1]
}

# 5) Boxmodel per scenario ----------

# Eén rij per kamer per dag voor één scenario
bereken_boxmodel <- function(scenario) {
  par <- pas_scenario_toe(baseline_parameters(), scenario)
  dagen <- dag_instellingen(par)
  stromen <- patientstromen(par, dagen)

  kamer_dag <- bezoeken_per_kamer(stromen, dagen) |>
    left_join(dagen, by = "dag") |>
    left_join(kamers, by = "behandelkamerId") |>
    left_join(capaciteit_per_dag(par), by = c("dag", "behandelkamerId")) |>
    mutate(
      behandelduur = gemBehandelduur * serviceFactor,
      werklastMinuten = bezoekenPerDag * behandelduur,
      beschikbareMinuten = capaciteit * workDayMinutes,
      rho = bereken_rho(werklastMinuten, beschikbareMinuten)
    )

  aankomstvariatie <- aankomstvariatie_per_kamer(
    kamer_dag,
    stromen,
    par$aankomst_cv^2
  )

  kamer_dag |>
    left_join(aankomstvariatie, by = c("dag", "behandelkamerId")) |>
    mutate(
      ca2 = coalesce(ca2, 1),
      wachttijd = if_else(
        rho < 1,
        wachttijd_allen_cunneen(
          bezoekenPerDag / workDayMinutes,
          behandelduur,
          capaciteit,
          ca2,
          behandelduur_cs2
        ),
        NA_real_ # instabiel: wachtrij groeit, geen evenwichtswachttijd
      )
    ) |>
    arrange(behandelkamerId, dag) |>
    group_by(behandelkamerId) |>
    mutate(
      achterstandMinuten = bereken_achterstand(
        werklastMinuten - beschikbareMinuten
      )
    ) |>
    ungroup() |>
    mutate(
      scenarioId = scenario$scenarioId,
      scenarioNaam = scenario$scenarioNaam,
      .before = 1
    )
}

boxmodel_per_dag <- map(scenarios, bereken_boxmodel) |>
  list_rbind()

# 6) Samenvattingen ----------

# Eerste dag waarop `conditie` waar is (NA als nooit)
eerste_dag_waarop <- function(dag, conditie) {
  if (any(conditie)) min(dag[conditie]) else NA_real_
}

# Mediane dagwachttijd over dagen met bezoek; NA (instabiel) telt als Inf
mediane_wachttijd <- function(wachttijd, bezoeken) {
  met_bezoek <- bezoeken > 0
  if (!any(met_bezoek)) {
    return(NA_real_)
  }
  median(coalesce(wachttijd[met_bezoek], Inf))
}

## Per scenario per kamer. benodigdeCapaciteit is gedimensioneerd op de
## drukste dag, zodat rho daar onder rho_doel blijft.
scenario_per_kamer <- boxmodel_per_dag |>
  group_by(
    scenarioId,
    scenarioNaam,
    behandelkamerId,
    behandelkamerNaam,
    behandelkamerType
  ) |>
  summarise(
    basisCapaciteit = first(basisCapaciteit),
    minCapaciteit = min(capaciteit),
    jaarRho = bereken_rho(sum(werklastMinuten), sum(beschikbareMinuten)),
    maxRho = max(rho),
    dagenOverbelast = sum(rho > 1),
    eersteOverbelasteDag = eerste_dag_waarop(dag, rho > 1),
    maxAchterstandUren = max(achterstandMinuten) / 60,
    # mediaan over dagen met bezoek; instabiele dagen (rho >= 1) tellen als Inf.
    # Geen gemiddelde: vlak onder rho = 1 schiet de wachttijd naar oneindig.
    medWachttijd = mediane_wachttijd(wachttijd, bezoekenPerDag),
    dagenBovenNorm = sum(
      bezoekenPerDag > 0 & (is.na(wachttijd) | wachttijd > wachttijd_norm)
    ),
    benodigdeCapaciteit = ceiling(
      max(werklastMinuten) / (rho_doel * workDayMinutes)
    ),
    .groups = "drop"
  ) |>
  mutate(extraCapaciteit = pmax(benodigdeCapaciteit - basisCapaciteit, 0))

## Eén rij per scenario
eerste_knelpunt <- function(naam, dag) {
  if (all(is.na(dag))) NA_character_ else naam[which.min(dag)]
}

instroom_per_scenario <- boxmodel_per_dag |>
  filter(behandelkamerId == receptie_id) |>
  group_by(scenarioId) |>
  summarise(instroomJaar = round(sum(bezoekenPerDag)), .groups = "drop")

scenario_overzicht <- scenario_per_kamer |>
  group_by(scenarioId, scenarioNaam) |>
  summarise(
    kamersOoitOverbelast = sum(dagenOverbelast > 0),
    kamersStructureelOverbelast = sum(jaarRho > 1),
    eersteKnelpunt = eerste_knelpunt(behandelkamerNaam, eersteOverbelasteDag),
    eersteKnelpuntDag = if (all(is.na(eersteOverbelasteDag))) {
      NA_real_
    } else {
      min(eersteOverbelasteDag, na.rm = TRUE)
    },
    extraCapaciteitTotaal = sum(extraCapaciteit),
    .groups = "drop"
  ) |>
  left_join(instroom_per_scenario, by = "scenarioId") |>
  relocate(instroomJaar, .after = scenarioNaam)

## Vergelijkingsmatrix: jaarRho per kamer (rijen) x scenario (kolommen)
jaar_rho_per_scenario <- scenario_per_kamer |>
  select(behandelkamerNaam, scenarioId, jaarRho) |>
  pivot_wider(names_from = scenarioId, values_from = jaarRho) |>
  arrange(desc(s0))

# 7) Uitvoer ----------

rond_af <- \(tabel) mutate(tabel, across(where(is.double), \(x) round(x, 2)))

print(rond_af(scenario_overzicht), n = Inf, width = Inf)
print(rond_af(jaar_rho_per_scenario), n = Inf, width = Inf)
print(
  scenario_per_kamer |>
    filter(scenarioId == "s0") |>
    select(-scenarioId, -scenarioNaam, -behandelkamerType) |>
    arrange(desc(maxRho)) |>
    rond_af(),
  n = Inf,
  width = Inf
)
