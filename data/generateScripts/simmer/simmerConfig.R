# Configuratiescript voor de simmer simulatie

## Duratie van de simulatie - je geeft het in minuten op.
dayMinutes <- 24 * 60
workDayMinutes <- 8 * 60
simDays <- 5
simDuration <- simDays * dayMinutes

## Simulatieresources - hoeveelheid servers/kamers dat elke resource heeft.
resource_definitie <- data.frame(
  id = c(
    1L, 2L, 3L, 4L, 5L,
    6L, 7L, 8L, 9L, 10L,
    11L, 12L, 13L, 14L, 15L,
    16L, 17L, 18L, 19L, 20L
  ),
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
    4, 4, 3, 1, 2,
    2, 3, 3, 2, 3,
    2, 1, 1, 1, 0,
    1, 1, 1, 1, 1
  ),
  stringsAsFactors = FALSE
)

receptieCapaciteit <- resource_definitie$capacity[resource_definitie$id == 1L]
gpOfficeCapaciteit <- resource_definitie$capacity[resource_definitie$id == 2L]
generalDiagnosisCapaciteit <- resource_definitie$capacity[resource_definitie$id == 3L]
wardCapaciteit <- resource_definitie$capacity[resource_definitie$id == 8L]
slackTongueCapaciteit <- resource_definitie$capacity[resource_definitie$id == 16L]

## Distributie/tempo waarmee nieuwe aankomsten van patienten worden gegenereerd
### Nu minimaal na 1 minuut, maximaal binnen 5 minuten.
aankomstDistributie <- function() runif(n = 1, min = 1, max = 5)

## Duraties van de behandeling van de verschillende resources
receptieTimeoutDuratie <- function() runif(1, 5, 10)
gpOfficeTimeoutDuratie <- function() runif(1, 10, 20)
generalDiagnosisTimeoutDuratie <- function() runif(1, 10, 20)
wardTimeoutDuratie <- function() runif(1, 15, 30)
slackTongueTimeoutDuratie <- function() runif(1, 15, 30)

# Bepalen van de aandoening van een patient
## in traj0 object wordt het attribuut aandoeningId bepaald:
aandoeningBepaling <- function() sample(x = c(1L:2L), size = 1, replace = T)
