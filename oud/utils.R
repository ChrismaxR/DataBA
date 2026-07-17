library(tidyverse)
set.seed(42)

# creëer vector voor alle datums in 2025
datum_vector <- seq(as.Date("2025-01-01"), as.Date("2025-12-31"), by = "day")

# creëer vector voor alle mogelijke tijdstippen op een dag met een interval van 6 minuten
tijd_vector <- format(
  seq(
    as.POSIXct("2000-01-01 09:00:00"),
    as.POSIXct("2000-01-01 21:00:00"),
    by = "1 min"
  ),
  "%H:%M:%S"
)

scenarios <- c("happyFlow", "foutieveDiagnose")

# tibble met mogelijke aandoeningen
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
    id = row_number(), # genereer een Id
    aandoeningOmschrijving
  )

# Eerste opzet van een patienten tabel
# ik kopel hier ook al een aprioriAandoening per patient om hen een te behandelen ziekte te geven
# (kan ik straks ook tegen testen dat behandeling niet juist is?)
# Daarnaast map ik ook de behandelroute en de te bezoeken kamers volgens mij logica uit story 4.
# Tot slot heb ik ook een scenario toegekend aan elke patiënt.

patientenStamTabel <- tibble::tibble(
  patientId = as.integer(seq(1, 16463, by = 1))
) |>
  mutate(
    aprioriAandoeningId = sample(aandoeningDimensies$id, n(), replace = TRUE),
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
      TRUE ~ "Error"
    ),
    diagnoseKamerTypeId = case_when(
      behandelRoute %in% c("A", "B", "C", "D", "E") ~ 2L,
      behandelRoute %in% c("F", "G", "H", "I", "J") ~ 3L,
      behandelRoute %in% c("K") ~ 4L,
      behandelRoute %in% c("L", "M", "N", "O") ~ 7L,
      behandelRoute %in% c("P", "Q") ~ 5L,
      behandelRoute %in% c("R", "S") ~ 6L,
      TRUE ~ -1L
    ),
    behandelKamerTypeId = case_when(
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
      TRUE ~ -1L
    ),
    patientScenario = sample(
      x = scenarios,
      n(),
      replace = TRUE,
      prob = c(0.95, 0.05)
    ),
    juisteDiagnoseKamerId = if_else(
      patientScenario == "foutieveDiagnose",
      2L,
      NA_integer_
    ),
    juisteBehandelKamerId = if_else(
      patientScenario == "foutieveDiagnose",
      8L,
      NA_integer_
    )
  )

eventDimensies <- tibble::tibble(
  eventType = c(
    "aankomst", # patiënt komt aan in het Ziekenhuis
    "inWachtrijReceptie", # patiënt neemt plaats in wachtrij voor de receptie
    "inReceptie", # patiënt schrijft zich in bij de receptie
    "inWachtrijDiagnose", # patiënt neemt plaats in de wachtrij voor diagnose
    "inDiagnose", #patiënt wordt gediagnostiseerd door diagnosepersoneel
    "inWachtrijBehandeling", # patiënt neemt plaats in wachtrij voor een passende behandeling
    "inBehandeling", # patiënt is in behandelkamer en ondergaat behandeling
    "ontslagen", # patiënt is behandeld en wordt ontslagen uit het ziekenhuis
    "inWachtrijNieuweDiagnose", # Na behandeling blijkt patiënt niet juiste diagnose te hebben gekregen en moet nogmaals gediagnostiseerd worden; patiënt neemt plaats in wachtrij voor herdiagnose
    "inNieuweDiagnose", # patiënt wordt nogmaals gediagnostiseerd
    "inWachtrijNieuweBehandeling", # patiënt neemt plaats in wachtrij voor een nieuwe behandeling
    "inNieuweBehandeling", # patiënt opnieuw in behandeling
    "vrij",
    "inGebruik",
    "machineKapot",
    "staffMetPauze",
    "staffOntslagGenomen"
  ),
  eventTypeCategorie = c(
    rep("patientEvent", 12),
    rep("kamerEvent", 5)
  )
) |>
  transmute(
    id = row_number(),
    eventType,
    eventTypeCategorie
  )

kamerDimensies <- tibble::tibble(
  kamerType = c(
    "Reception",
    "GP’s Office",
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
  )
) |>
  transmute(
    id = row_number(),
    kamerType
  ) |>
  mutate(
    kamerCount = c(
      4, # Reception
      4, # GP's Office
      3, # General Diagnosis Room
      1, # Cardiogram
      2, # Scanner
      2, # Ultrascan
      3, # X-Ray
      3, # The Ward
      2, # Psychiatric Room
      3, # Pharmacy
      2, # Operating Theatre
      1, # Inflation Room
      1, # DNA Fixer
      1, # Hair Restoration
      0, # ResearchDept (unused in routes)
      1, # Slack Tongue Clinic
      1, # Fracture Clinic
      1, # Electrolysis
      1, # Jelly Vat
      1 # Decontamination
    )
  ) |>
  uncount(kamerCount, .remove = FALSE, .id = "room_seq") |>
  mutate(
    kamerId = row_number(),
    kamerTypeId = id,
    volgendeVrijeDatumTijd = as.POSIXct(
      # houdt bij wanneer een specifieke kamer vrij komt - initieel op allereerste minuut van 2025 gezet
      "2025-01-01 00:00:00",
      tz = "UTC"
    ),
    minDuratieKamer = case_when(
      kamerTypeId == 1 ~ 5,
      kamerTypeId %in% c(2, 3) ~ 9,
      kamerTypeId %in% c(4, 5) ~ 11,
      kamerTypeId %in% c(6, 7) ~ 15,
      kamerTypeId %in% c(8, 9, 10) ~ 25,
      kamerTypeId %in% c(11, 12) ~ 45,
      kamerTypeId %in% c(13, 14, 15) ~ 55,
      T ~ 60
    ),
    maxDuratieKamer = case_when(
      kamerTypeId == 1 ~ 10,
      kamerTypeId %in% c(2, 3) ~ 15,
      kamerTypeId %in% c(4, 5) ~ 17,
      kamerTypeId %in% c(6, 7) ~ 20,
      kamerTypeId %in% c(8, 9, 10) ~ 35,
      kamerTypeId %in% c(11, 12) ~ 60,
      kamerTypeId %in% c(13, 14, 15) ~ 75,
      T ~ 80
    ),
    maxDuratieMankement = case_when(
      kamerTypeId %in% c(1, 2, 3) ~ 0,
      kamerTypeId %in% c(4, 5) ~ 20,
      kamerTypeId %in% c(6, 7) ~ 30,
      kamerTypeId %in% c(8, 9, 10) ~ 15,
      kamerTypeId %in% c(11, 12) ~ 30,
      kamerTypeId %in% c(13, 14, 15) ~ 15,
      T ~ 60
    )
  ) |>
  transmute(
    kamerId,
    kamerTypeId,
    kamerType,
    volgendeVrijeDatumTijd,
    minDuratieKamer = as.integer(minDuratieKamer),
    maxDuratieKamer = as.integer(maxDuratieKamer),
    maxDuratieMankement = as.integer(maxDuratieMankement)
  )
