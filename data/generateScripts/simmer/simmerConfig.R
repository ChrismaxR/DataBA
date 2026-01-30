# Configuratiescript voor de simmer simulatie

## Duratie van de simulatie - je geeft het in minuten op.
simDuration <- 8 * 60 # aantal uur simulatie

## Simulatieresources - hoeveelheid servers/kamers dat elke resource heeft.
receptieCapaciteit <- 3
gpOfficeCapaciteit <- 2
generalDiagnosisCapaciteit <- 2
wardCapaciteit <- 2
slackTongueCapaciteit <- 2

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
