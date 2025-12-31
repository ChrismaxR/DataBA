library(tidyverse)

set.seed(42)

# creëer vector voor alle datums in 2025
datum_vector <- seq(as.Date("2025-01-01"), as.Date("2025-12-31"), by = "day")

# creëer vector voor alle mogelijke tijdstippen op een dag met een interval van 6 minuten
tijd_vector <- format(
  seq(
    as.POSIXct("2000-01-01 00:00:00"),
    as.POSIXct("2000-01-01 23:59:00"),
    by = "6 min"
  ),
  "%H:%M:%S"
)

scenario <- c("Easy", "Medium", "Hard", "Ultra hard")

# vector met mogelijke aandoeningen
source("data/generateScripts/dim_diagnose.R")
diagnoseOmschrijving

# Eerste opzet van een patienten tabel
# ik kopel hier ook al een aprioriAandoening per patient om hen een te behandelen ziekte te geven
# (kan ik straks ook tegen testen dat behandeling niet juist is?)
# Daarnaast map ik ook de behandelroute en de te bezoeken kamers volgens mij logica uit story 4.
# Tot slot heb ik ook een scenario toegekend aan elke patiënt.

patienten <- tibble::tibble(
  patientId = as.integer(seq(1, 16463, by = 1))
) |>
  mutate(
    aprioriAandoening = sample(diagnoseOmschrijving, n(), replace = TRUE),
    behandelRoute = case_when(
      aprioriAandoening %in%
        c("Sleeping Illness", "Discrete Itching", "Fake Blood") ~ "A",
      aprioriAandoening %in%
        c(
          "The Squits",
          "Sweaty Palms",
          "Gastric Ejections",
          "Uncommon Cold"
        ) ~ "B",
      aprioriAandoening %in% c("Chronic Nosehair", "Hairyitis") ~ "C",
      aprioriAandoening %in% c("Baldness") ~ "D",
      aprioriAandoening %in%
        c("King Complex", "Infectious Laughter", "TV Personalities") ~ "E",
      aprioriAandoening %in%
        c("Ruptured Nodules", "Broken Wind", "Golf Stones", "Iron Lungs") ~ "F",
      aprioriAandoening %in%
        c("Gut Rot", "Heaped Piles") ~ "G",
      aprioriAandoening %in%
        c("3rd Degree Sideburns") ~ "H",
      aprioriAandoening %in%
        c("Bloaty Head") ~ "I",
      aprioriAandoening %in%
        c("Slack Tongue") ~ "J",
      aprioriAandoening %in%
        c("Broken Heart") ~ "K",
      aprioriAandoening %in%
        c(
          "Spare Ribs",
          "Corrugated Ankles",
          "Fractured Bones"
        ) ~ "L",
      aprioriAandoening %in%
        c("Kidney Beans") ~ "M",
      aprioriAandoening %in%
        c("Unexpected Swelling") ~ "N",
      aprioriAandoening %in%
        c("Serious Radiation") ~ "O",
      aprioriAandoening %in%
        c("Jellyitis") ~ "P",
      aprioriAandoening %in%
        c("Transparency") ~ "Q",
      aprioriAandoening %in%
        c("Invisibility") ~ "R",
      aprioriAandoening %in%
        c("Alien DNA") ~ "S",
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
