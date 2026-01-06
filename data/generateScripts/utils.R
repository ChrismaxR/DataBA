library(tidyverse)
set.seed(42)

# creëer vector voor alle datums in 2025
datum_vector <- seq(as.Date("2025-01-01"), as.Date("2025-12-31"), by = "day")

# creëer vector voor alle mogelijke tijdstippen op een dag met een interval van 6 minuten
tijd_vector <- format(
  seq(
    as.POSIXct("2000-01-01 08:45:00"),
    as.POSIXct("2000-01-01 21:00:00"),
    by = "15 min"
  ),
  "%H:%M:%S"
)

scenario <- c("Easy", "Medium", "Hard", "Ultra hard")

# vector met mogelijke aandoeningen
aandoening <- tibble::tibble(
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
    id = row_number(), # genereer een Id
    aandoeningOmschrijving
  )

# Eerste opzet van een patienten tabel
# ik kopel hier ook al een aprioriAandoening per patient om hen een te behandelen ziekte te geven
# (kan ik straks ook tegen testen dat behandeling niet juist is?)
# Daarnaast map ik ook de behandelroute en de te bezoeken kamers volgens mij logica uit story 4.
# Tot slot heb ik ook een scenario toegekend aan elke patiënt.

patienten <- tibble::tibble(
  patientId = as.integer(seq(1, 16463, by = 1))
) |>
  mutate(
    aprioriAandoeningId = sample(aandoening$id, n(), replace = TRUE),
    behandelRoute = case_when(
      aprioriAandoeningId %in% c(1:3) ~ "A",
      aprioriAandoeningId %in% c(4:7) ~ "B",
      aprioriAandoeningId %in% c(8, 9) ~ "C",
      aprioriAandoeningId %in% c(10) ~ "D",
      aprioriAandoeningId %in% c(11:13) ~ "E",
      aprioriAandoeningId %in% c(14:17) ~ "F",
      aprioriAandoeningId %in% c(18, 19) ~ "G",
      aprioriAandoeningId %in% c(20) ~ "H",
      aprioriAandoeningId %in% c(21) ~ "I",
      aprioriAandoeningId %in% c(22) ~ "J",
      aprioriAandoeningId %in% c(23) ~ "K",
      aprioriAandoeningId %in% c(24:26) ~ "L",
      aprioriAandoeningId %in% c(27) ~ "M",
      aprioriAandoeningId %in% c(28) ~ "N",
      aprioriAandoeningId %in% c(29) ~ "O",
      aprioriAandoeningId %in% c(30) ~ "P",
      aprioriAandoeningId %in% c(31) ~ "Q",
      aprioriAandoeningId %in% c(32) ~ "R",
      aprioriAandoeningId %in% c(33) ~ "S",
      T ~ "Error"
    ),
    diagnoseKamerId = case_when(
      behandelRoute %in% c("A", "B", "C", "D", "E") ~ 2L,
      behandelRoute %in% c("F", "G", "H", "I", "J") ~ 3L,
      behandelRoute %in% c("K") ~ 4L,
      behandelRoute %in% c("L", "M", "N", "O") ~ 7L,
      behandelRoute %in% c("P", "Q") ~ 5L,
      behandelRoute %in% c("R", "S") ~ 6L,
      T ~ -1L
    ),
    behandelKamerId = case_when(
      behandelRoute %in% c("A") ~ 8L,
      behandelRoute %in% c("B", "G", "N", "Q", "R") ~ 10L,
      behandelRoute %in% c("C", "H") ~ 18L,
      behandelRoute %in% c("D") ~ 14L,
      behandelRoute %in% c("E") ~ 9L,
      behandelRoute %in% c("F", "M") ~ 11L,
      behandelRoute %in% c("I") ~ 12L,
      behandelRoute %in% c("J") ~ 16L,
      behandelRoute %in% c("K", "L") ~ 17L,
      behandelRoute %in% c("O") ~ 20L,
      behandelRoute %in% c("P") ~ 19L,
      behandelRoute %in% c("S") ~ 13L,
      T ~ -1L
    ),
    scenario = sample(
      scenario,
      n(),
      replace = TRUE,
      prob = c(0.70, 0.20, 0.05, 0.05)
    )
  )

events <- tibble::tibble(
  eventType = c(
    "wachtenOpReceptie",
    "inReceptie",
    "wachtenOpDiagnose",
    "inDiagnose",
    "wachtenOpBehandeling",
    "inBehandeling",
    "ontslagen",
    "wachtenOpNieuweDiagnose",
    "vrij",
    "inGebruik",
    "machineKapot",
    "staffMetPauze",
    "staffOntslagGenomen"
  ),
  eventTypeCategorie = c(
    rep("patientEvent", 8),
    rep("kamerEvent", 5)
  )
) |>
  transmute(
    id = row_number(),
    eventType,
    eventTypeCategorie
  )
