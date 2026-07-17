library("tidyverse")
Sys.setlocale("LC_TIME", "nl_NL")


tictoc::tic()
source("src/generateScripts/simmerConfig.R")
source("src/generateScripts/simmerImplementatie.R")
tictoc::toc()

# glimpse(events_wrangle)
# glimpse(log_aankomst_ontslag)
# glimpse(resources)

totaal <- events_wrangle |>
  summarise(
    behandelkamers = n_distinct(resource),
    aandoeningen = n_distinct(aandoeningId),
    patienten = n_distinct(name),
    gemiddeldeBehandeltijdMin = mean(activityTime),
    gemiddeldeWachttijdMin = mean(waitTime),
    mediaanWachttijdMin = median(waitTime)
  )

aankomst_onstlag <- log_aankomst_ontslag |>
  mutate(
    aankomstMaand = floor_date(date(aankomstTijdstipReal), unit = "month"),
    aankomstMaandLabel = month(
      aankomstMaand,
      label = T,
      abbr = F
    ),
    ontslagen = if_else(is.na(ontslagTijdstip), F, T)
  ) |>
  group_by(
    aankomstMaand,
    aankomstMaandLabel,
    ontslagen,
    aandoeningOmschrijving
  ) |>
  summarise(
    patienten = n_distinct(patient),
    gemiddeldeTijdInZiekenhuisMin = mean(duratieInZiekenhuis, na.rm = T)
  ) |>
  transmute(
    maand = aankomstMaand,
    maandLabel = aankomstMaandLabel,
    ontslagen,
    aandoeningOmschrijving,
    patienten,
    gemiddeldeTijdInZiekenhuisMin
  )


capaciteitMaandResourceKamerNummer <- events_wrangle |>
  mutate(
    maand = floor_date(date(endTimeReal), unit = "month"),
    maandLabel = month(maand, label = T)
  ) |>
  group_by(maand, maandLabel, resource, kamerNummer) |>
  summarise(
    capaciteitDagen = n_distinct(date(endTimeReal)),
    capaciteitMin = capaciteitDagen * 480, # aantal uren dat toko open is
    totaleBehandeltijdMin = sum(activityTime),
    benuttingPerc = totaleBehandeltijdMin / capaciteitMin,
    wachttijdMin = sum(waitTime),
    patientenBehandeld = n_distinct(name),
    gemiddeldeBehandeltijdPerPatientMin = totaleBehandeltijdMin /
      patientenBehandeld,
    gemiddeldeWachttijdPerPatientMin = wachttijdMin / patientenBehandeld,
  ) |>
  ungroup() |>
  transmute(
    maand,
    maandLabel,
    kamer = str_c(resource, " ", kamerNummer),
    totaleBehandeltijdMin,
    benuttingPerc,
    wachttijdMin,
    patientenBehandeld,
    gemiddeldeBehandeltijdPerPatientMin,
    gemiddeldeWachttijdPerPatientMin
  )


behandeltijdMaandResourceAandoening <- events_wrangle |>
  mutate(
    maand = floor_date(date(startTimeReal), unit = "month"),
    maandLabel = month(maand, label = T)
  ) |>
  group_by(maand, maandLabel, resource, aandoeningOmschrijving) |>
  summarise(
    patientenBehandeld = n_distinct(name),
    somBehandeltijd = sum(activityTime),
    gemBehandeltijd = mean(activityTime),
    mediaanBehandeltijd = median(activityTime)
  ) |>
  ungroup() |>
  transmute(
    maand,
    maandLabel,
    kamerType = resource,
    aandoening = aandoeningOmschrijving,
    patientenBehandeld,
    somBehandeltijdMin = somBehandeltijd,
    gemBehandeltijdMin = gemBehandeltijd,
    mediaanBehandeltijdMin = mediaanBehandeltijd
  )
