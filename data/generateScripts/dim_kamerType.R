library(tidyverse)

dim_kamerType <- tibble::tibble(
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
  )
