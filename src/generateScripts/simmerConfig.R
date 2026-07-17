# Configuratiescript voor de simmer simulatie

## Duratie van de simulatie - je geeft het in minuten op.
dayMinutes <- 24 * 60
workDayMinutes <- 8 * 60
simDays <- 365
simDuration <- simDays * dayMinutes

## Simulatieresources - hoeveelheid servers/kamers dat elke resource heeft.
resource_definitie <- data.frame(
  id = c(1L:20L),
  resourceName = c(
    "Reception",
    "GP's Office",
    "General Diagnosis Room",
    "Cardiogram",
    "Scanner",
    "Ultrascan",
    "X-Ray",
    "The Ward",
    "Psychiatric Room",
    "Pharmacy",
    "Operating Theatre",
    "Inflation Room",
    "DNA Fixer",
    "Hair Restoration",
    "ResearchDept",
    "Slack Tongue Clinic",
    "Fracture Clinic",
    "Electrolysis",
    "Jelly Vat",
    "Decontamination"
  ),
  capacity = c(
    3,
    3,
    1,
    1,
    2,
    3,
    2,
    1,
    2,
    2,
    2,
    1,
    1,
    3,
    2,
    3,
    4,
    2,
    1,
    1
  ),
  stringsAsFactors = FALSE
)

receptieCapaciteit <- resource_definitie$capacity[resource_definitie$id == 1L]
gpOfficeCapaciteit <- resource_definitie$capacity[resource_definitie$id == 2L]
generalDiagnosisCapaciteit <- resource_definitie$capacity[
  resource_definitie$id == 3L
]
wardCapaciteit <- resource_definitie$capacity[resource_definitie$id == 8L]
slackTongueCapaciteit <- resource_definitie$capacity[
  resource_definitie$id == 16L
]

## Distributie/tempo waarmee nieuwe aankomsten van patienten worden gegenereerd
### Kwartaalschema: rate bepaalt gemiddelde tussentijd (minuten) tussen aankomsten.
aankomst_schema <- tibble::tibble(
  dag_van = c(0, 90, 180, 270),
  rate = c(1 / 3, 1 / 2, 1 / 4, 1 / 3) # Q1 normaal, Q2 druker, Q3 rustiger, Q4 normaal
)

## Standaard aankomstDistributie (wordt overschreven in simmerImplementatie.R)
aankomstDistributie <- function() rexp(n = 1, rate = 1 / 3)

## Duraties van de behandeling van de verschillende resources
receptieTimeoutDuratie <- function() runif(1, 5, 10)
gpOfficeTimeoutDuratie <- function() runif(1, 10, 20)
generalDiagnosisTimeoutDuratie <- function() runif(1, 10, 20)
wardTimeoutDuratie <- function() runif(1, 15, 30)
slackTongueTimeoutDuratie <- function() runif(1, 15, 30)

# Bepalen van de aandoening van een patient
## in traj0 object wordt het attribuut aandoeningId bepaald:
aandoeningBepaling <- function() sample(x = c(1L:2L), size = 1, replace = T)

## Variabiliteit in behandelduur per kwartaal (vermenigvuldiger op basis service tijden)
service_schema <- tibble::tibble(
  dag_van = c(0, 90, 180, 270),
  multiplier = c(1.0, 1.2, 0.9, 1.1) # Q2 trager, Q3 sneller, Q4 licht trager
)

## Epidemie-instellingen (Infectious Laughter, bellcurve piek midden van het jaar)
epidemie_aandoening_id <- 12L
epidemie_piek_dag <- 182
epidemie_sd_dagen <- 20
epidemie_piek_gewicht <- 25

## Geplande capaciteitswijzigingen gedurende het jaar
capaciteit_schema <- tibble::tibble(
  dag = c(90, 180, 270, 90, 180, 270, 90, 180, 270),
  resourceName = c(
    "Psychiatric Room",
    "Psychiatric Room",
    "Psychiatric Room",
    "Hair Restoration",
    "Hair Restoration",
    "Hair Restoration",
    "Slack Tongue Clinic",
    "Slack Tongue Clinic",
    "Slack Tongue Clinic"
  ),
  nieuwe_cap = c(2, 3, 1, 2, 1, 1, 3, 2, 1)
)

# Look up tabellen

aandoeningDimensies <- tibble::tibble(
  aandoeningOmschrijving = c(
    "Sleeping Illness",
    "Discrete Itching",
    "Fake Blood",
    "The Squits",
    "Sweaty Palms",
    "Gastric Ejections",
    "Uncommon Cold",
    "Chronic Nosehair",
    "Hairyitis",
    "Baldness",
    "King Complex",
    "Infectious Laughter",
    "TV Personalities",
    "Ruptured Nodules",
    "Broken Wind",
    "Golf Stones",
    "Iron Lungs",
    "Gut Rot",
    "Heaped Piles",
    "3rd Degree Sideburns",
    "Bloaty Head",
    "Slack Tongue",
    "Broken Heart",
    "Spare Ribs",
    "Corrugated Ankles",
    "Fractured Bones",
    "Kidney Beans",
    "Unexpected Swelling",
    "Serious Radiation",
    "Jellyitis",
    "Transparency",
    "Invisibility",
    "Alien DNA"
  )
) |>
  transmute(
    id = as.character(row_number()), # genereer een Id
    aandoeningOmschrijving
  )

# Configuratie voor simmerStatistics

# helperfuncties --------------

# Zet de starttijdstip om vanuit te rekenen
simOrigin <- as.POSIXct("2025-01-01 09:00:00", tz = "UTC")

# conversiefunctie om relatieve simmertijdstippen om te zetten naar "echte" datetimes
to_datetime <- function(timeMinutes) {
  simOrigin + as.difftime(timeMinutes, units = "mins")
}
