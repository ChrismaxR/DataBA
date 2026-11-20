# Scenariodefinities voor het meerjarig beleidsplan (README §3)
## Elk scenario is een set overrides op de baseline-parameters uit simmerConfig.R.
## simmerConfig.R blijft de enige bron van waarheid: dit script leest de
## baselinewaarden daaruit en legt alleen de afwijkingen per scenario vast.
## Gebruikt door src/modelScripts/boxModel.R, later ook door run_scenario().
## Vereist dat simmerConfig.R al gesourcet is.

# 1) Baseline-parameters ----------

# Bundelt de scenariogevoelige config-objecten in één lijst
baseline_parameters <- function() {
  list(
    aankomst_schema = aankomst_schema,
    aankomst_cv = 1, # exponentiële tussenaankomsttijden (aankomstDistributie)
    service_schema = service_schema,
    resource_definitie = tibble::as_tibble(resource_definitie),
    capaciteit_schema = capaciteit_schema,
    aandoening_gewichten = rep(1, nrow(aandoeningDimensies)),
    epidemie_golven = tibble::tibble(
      aandoeningId = epidemie_aandoening_id,
      piekDag = epidemie_piek_dag,
      sdDagen = epidemie_sd_dagen,
      piekGewicht = epidemie_piek_gewicht
    )
  )
}

# 2) Hulpfuncties voor overrides ----------
# Een override is een vaste waarde, of een functie die de baselinewaarde
# ontvangt en de aangepaste waarde teruggeeft.

# Aankomstintensiteit in elk kwartaal met `factor` vermenigvuldigen
verhoog_aankomsten <- function(factor) {
  function(schema) dplyr::mutate(schema, rate = rate * factor)
}

# Capaciteit van de genoemde kamers met `delta` aanpassen (niet onder 0)
pas_capaciteit_aan <- function(kamers, delta) {
  function(definitie) {
    dplyr::mutate(
      definitie,
      capacity = dplyr::if_else(
        resourceName %in% kamers,
        pmax(capacity + delta, 0),
        capacity
      )
    )
  }
}

# Geplande capaciteit (capaciteit_schema) van de genoemde kamers met `delta`
# aanpassen, zodat een permanente wijziging ook na geplande wijzigingen geldt
pas_geplande_capaciteit_aan <- function(kamers, delta) {
  function(schema) {
    dplyr::mutate(
      schema,
      nieuwe_cap = dplyr::if_else(
        resourceName %in% kamers,
        pmax(nieuwe_cap + delta, 0),
        nieuwe_cap
      )
    )
  }
}

# Gewicht van de genoemde aandoeningen met `factor` vermenigvuldigen
verzwaar_aandoeningen <- function(aandoening_ids, factor) {
  function(gewichten) {
    gewichten[aandoening_ids] <- gewichten[aandoening_ids] * factor
    gewichten
  }
}

# Past de overrides van een scenario toe op de baseline-parameters
pas_scenario_toe <- function(basis, scenario) {
  purrr::reduce(
    names(scenario$overrides),
    function(par, naam) {
      override <- scenario$overrides[[naam]]
      par[[naam]] <- if (is.function(override)) override(par[[naam]]) else override
      par
    },
    .init = basis
  )
}

# 3) Scenario's ----------

scenarios <- list(
  # 0. Huidige operatie
  list(
    scenarioId = "s0",
    scenarioNaam = "Baseline 2026",
    omschrijving = "Huidige operatie, standaardwaarden uit simmerConfig.R",
    overrides = list()
  ),

  # 1. Meer welvaarts- en ouderdomsziekten: deze aandoeningen komen 2x vaker voor.
  # PLACEHOLDER: keuze van aandoeningen nog vast te stellen.
  # (8 Chronic Nosehair, 10 Baldness, 16 Golf Stones, 18 Gut Rot,
  #  19 Heaped Piles, 23 Broken Heart)
  list(
    scenarioId = "s1",
    scenarioNaam = "Verschuiving in ziekten",
    omschrijving = "Welvaarts- en ouderdomsziekten 2x zo vaak",
    overrides = list(
      aandoening_gewichten = verzwaar_aandoeningen(c(8, 10, 16, 18, 19, 23), 2)
    )
  ),

  # 2. Epidemische golven: de bestaande zomergolf plus een winter- en
  # najaarsgolf van Uncommon Cold (id 7). PLACEHOLDER: golven nog af te stemmen.
  list(
    scenarioId = "s2",
    scenarioNaam = "Infectieziekten",
    omschrijving = "Drie epidemische golven van twee infectieziekten",
    overrides = list(
      epidemie_golven = function(golven) {
        dplyr::bind_rows(
          golven,
          tibble::tibble(
            aandoeningId = c(7L, 7L),
            piekDag = c(30, 330),
            sdDagen = c(15, 15),
            piekGewicht = c(15, 15)
          )
        )
      }
    )
  ),

  # 3. Grotere populatie: varianten +10/+20/+30% aankomsten
  list(
    scenarioId = "s3a",
    scenarioNaam = "Grotere populatie +10%",
    omschrijving = "Aankomstintensiteit +10% in elk kwartaal",
    overrides = list(aankomst_schema = verhoog_aankomsten(1.1))
  ),
  list(
    scenarioId = "s3b",
    scenarioNaam = "Grotere populatie +20%",
    omschrijving = "Aankomstintensiteit +20% in elk kwartaal",
    overrides = list(aankomst_schema = verhoog_aankomsten(1.2))
  ),
  list(
    scenarioId = "s3c",
    scenarioNaam = "Grotere populatie +30%",
    omschrijving = "Aankomstintensiteit +30% in elk kwartaal",
    overrides = list(aankomst_schema = verhoog_aankomsten(1.3))
  ),

  # 3d. Grilliger: +20% en tussenaankomsttijden met meer spreiding (CV 1.5
  # in plaats van 1 bij de exponentiële verdeling)
  list(
    scenarioId = "s3d",
    scenarioNaam = "Grotere en grilligere populatie",
    omschrijving = "Aankomstintensiteit +20% en variatiecoëfficiënt 1.5",
    overrides = list(
      aankomst_schema = verhoog_aankomsten(1.2),
      aankomst_cv = 1.5
    )
  ),

  # 4a. Permanente krapte: één kamer minder bij de huidige knelpunten
  # (uit het boxmodel). The Ward gaat daarmee van 1 naar 0: volledig dicht.
  list(
    scenarioId = "s4a",
    scenarioNaam = "Arbeidsmarktkrapte permanent",
    omschrijving = "Eén kamer minder: Electrolysis, The Ward, Psychiatric Room",
    overrides = list(
      resource_definitie = pas_capaciteit_aan(
        c("Electrolysis", "The Ward", "Psychiatric Room"),
        -1
      ),
      capaciteit_schema = pas_geplande_capaciteit_aan(
        c("Electrolysis", "The Ward", "Psychiatric Room"),
        -1
      )
    )
  ),

  # 4b. Tijdelijke krapte: Pharmacy en Operating Theatre een kwartaal op
  # halve bezetting. PLACEHOLDER: kamers en periodes nog af te stemmen.
  list(
    scenarioId = "s4b",
    scenarioNaam = "Arbeidsmarktkrapte tijdelijk",
    omschrijving = "Pharmacy en Operating Theatre dag 120-210 op 2 kamers",
    overrides = list(
      capaciteit_schema = function(schema) {
        dplyr::bind_rows(
          schema,
          tibble::tibble(
            dag = c(120, 210, 120, 210),
            resourceName = c(
              "Pharmacy",
              "Pharmacy",
              "Operating Theatre",
              "Operating Theatre"
            ),
            nieuwe_cap = c(2, 4, 2, 4)
          )
        )
      }
    )
  )
)
