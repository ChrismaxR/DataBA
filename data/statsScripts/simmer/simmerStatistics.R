# Script om wat statistieken over de gesimuleerde data uit simmerImplementatie.R
# te halen en een beeld te vormen over hoe goed de simulatie opzet is.

library("tidyverse")
library("patchwork")
source("data/generateScripts/simmer/simmerConfig.R")
source("data/generateScripts/simmer/simmerImplementatie.R")

# helperfuncties --------------

simOrigin <- as.POSIXct("2025-01-01 09:00:00", tz = "UTC")

to_datetime <- function(timeMinutes) {
  simOrigin + as.difftime(timeMinutes, units = "mins")
}

# Wrangle data -------------
# waitTime berekenen (maar nog niet zeker of dit de juiste manier is), factor maken van resources
# plus daadwerkelijke tijdstippen maken m.b.v. helper uit
events_wrangle <- events |>
  mutate(
    waitTime = (endTime - activityTime) - startTime, # is dit de juiste berekening?
    resource = factor(
      resource,
      levels = resource_definitie$resourceName
    ),
    startTimeReal = to_datetime(startTime),
    endTimeReal = to_datetime(endTime),
    startTimeMonth = month(startTimeReal, label = T),
    endTimeMonth = month(endTimeReal, label = T)
  )

# In de log_() functie kan ik allemaal eigenschappen van patienten kwijt
# als ik dat doet met de vorm "eigenschap = nummeriekeWaarde", dan kan ik deze eenvoudig in deze tibble kwijt.
patientAttributes <- log_df |>
  filter(str_detect(message, "^aandoeningId")) |>
  transmute(
    patient = arrival,
    type = str_trim(str_extract(message, "^[^=]+")),
    value = str_extract(message, "(?<=\\=\\s).*")
  ) |>
  pivot_wider(names_from = type, values_from = value) |>
  left_join(aandoeningDimensies, by = c("aandoeningId" = "id"))

log_aankomst_ontslag <- log_df |>
  filter(message %in% c("aankomstTijdstip", "ontslagTijdstip")) |>
  pivot_wider(names_from = message, values_from = time) |>
  mutate(
    duratieInZiekenhuis = if_else(
      !is.na(ontslagTijdstip),
      ontslagTijdstip - aankomstTijdstip,
      NA_real_
    ),
    aankomstTijdstipReal = to_datetime(aankomstTijdstip),
    ontslagTijdstipReal = to_datetime(ontslagTijdstip),
    aankomstTijdstipMonth = month(aankomstTijdstipReal, label = T),
    ontstlagTijdstipMonth = month(ontslagTijdstipReal, label = T)
  ) |>
  rename(patient = 1) |>
  left_join(patientAttributes, by = "patient")

# Wat wil ik berekenen?  ----------------

# wachttijden: per datum (eigenlijk maand), aandoening, kamerType, scenario

# benutting: % van de tijd dat resource in gebruik is van potentieel
# per datum (eigenlijk maand), aandoening, kamerType, scenario

## Wachttijden
events_wrangle |>
  filter(name %in% c("patient25", "patient88")) |>
  group_by(name) |> # ook per resource breakdown doen ipv patient
  summarise(totalWaitTime = sum(waitTime))


# Hoe zien aankomst tijdstippen er uit?
histogram_aankomsttijden <- events_wrangle |>
  #filter(resource == "Receptie") |>
  ggplot(
    aes(
      x = hms::as_hms(startTimeReal),
      fill = fct_rev(fct_inorder(resource))
    ),
    colour = "white"
  ) +
  geom_histogram(bins = 50) +
  #scale_x_datetime() +
  labs(
    title = "Verdeling Aankomsten per kamerType van patiënten in mijn simulatie",
    subtitle = "",
    y = "Aankomsten patiënten",
    x = "Aanvangstijdstip kamer",
    fill = "Kamer"
  )

# Hoe ziet de verdeling van behandeltijden per kamerType eruit?
boxplot_behandeltijden <- events_wrangle |>
  ggplot(aes(
    y = fct_infreq(resource),
    x = activityTime,
    fill = resource
  )) +
  geom_boxplot() +
  geom_jitter(alpha = .6, width = .2, height = 0) +
  theme(legend.position = "none") +
  labs(
    title = "Verdeling behandeltijden per kamerType",
    #subtitle = "",
    y = "Behandeltijd in minuten",
    x = NULL
  )

# Hoe ziet de verdeling van wachttijden per kamerType eruit?
boxplot_wachttijden <- events_wrangle |>
  ggplot(aes(
    y = forcats::fct_infreq(resource),
    x = waitTime,
    fill = resource
  )) +
  geom_boxplot() +
  geom_jitter(alpha = .6, width = .2, height = 0) +
  theme(legend.position = "none") +
  #scale_x_log10() +
  labs(
    title = "Verdeling wachttijden per kamerType",
    #subtitle = "",
    y = "Wachttijd in minuten",
    x = NULL
  )


# Benutting ---------------
# wat voor data heb ik nodig om dit te gaan berekenen?
# starttijd dat kamer in behandeling is + eindtijd -> geeft blokken van benutting.
# een totale tijd dat een behandelkamer beschibaar is (openingstijden)

tabel_benutting <- events_wrangle |>
  group_by(resource) |>
  summarise(
    sumWaitTime = sum(waitTime),
    sumActivityTime = sum(activityTime)
  ) |>
  left_join(
    resource_definitie |>
      transmute(resource = resourceName, capacity),
    by = "resource"
  ) |>
  mutate(
    potentialActivityTime = capacity * simDuration,
    utilization = if_else(
      potentialActivityTime > 0,
      sumActivityTime / potentialActivityTime,
      NA_real_
    )
  )

barplot_benutting <- tabel_benutting |>
  ggplot(aes(
    y = fct_reorder(resource, utilization),
    x = utilization,
    fill = resource
  )) +
  geom_bar(stat = "identity") +
  geom_text(
    aes(
      label = scales::percent(
        utilization,
        big.mark = ".",
        decimal.mark = ",",
        accuracy = .2
      )
    )
  ) +
  scale_x_continuous(labels = scales::percent_format()) +
  labs(
    title = "Benutting per kamerType",
    subtitle = "dus niet per server/individuele kamer",
    x = "Benuttingspercentage",
    y = NULL
  )

# Patienten die binnen een dag een behandelpad afgerond hebben
events_wrangle |>
  #filter(name == "patient0") |>
  count(name, name = "aantalRegels") |>
  count(aantalRegels, name = "aantalPatienten") |>
  mutate(
    perc = aantalPatienten / sum(aantalPatienten)
  )

barplot_ontslag <- log_aankomst_ontslag |>
  mutate(
    isOntslagen = if_else(
      is.na(duratieInZiekenhuis),
      "Niet ontslagen",
      "ontslagen"
    )
  ) |>
  count(isOntslagen, aandoeningOmschrijving) |>
  ggplot(aes(x = isOntslagen, y = n, fill = aandoeningOmschrijving)) +
  geom_col() +
  labs(
    title = "Verdeling patienten die ontslagen zijn gedurende de dag",
    subtitle = "met inzicht in aandoening",
    x = NULL,
    y = "Aantal patiënten"
  )


histogram_duratie_in_ziekenhuis <- log_aankomst_ontslag |>
  filter(!is.na(duratieInZiekenhuis)) |>
  ggplot(aes(x = duratieInZiekenhuis, fill = aandoeningId)) +
  geom_histogram(binwidth = 30) +
  facet_wrap(~aandoeningId) +
  labs(
    title = "Verdeling minuten in ziekenhuis",
    y = "Aantal patienten",
    x = "Duratie in minuten"
  )

# Rapporteer in 1 overzicht en schrijf weg naar schrijf -------------
rapport <- histogram_aankomsttijden +
  boxplot_behandeltijden +
  boxplot_wachttijden +
  barplot_benutting +
  barplot_ontslag +
  histogram_duratie_in_ziekenhuis
