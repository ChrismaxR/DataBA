# Script om wat statistieken over de gesimuleerde data uit simmerImplementatie.R
# te halen en een beeld te vormen over hoe goed de simulatie opzet is.

library("tidyverse")
library("patchwork")

tictoc::tic()
source("data/generateScripts/simmerConfig.R")
source("data/generateScripts/simmerImplementatie.R")
tictoc::toc()

glimpse(events_wrangle)

events_wrangle |>
  ##group_by(startTimeMonth) |>
  summarise(
    patienten = n_distinct(name)
  )

log_aankomst_ontslag |>
  ##group_by(aankomstTijdstipMonth) |>
  summarise(
    patienten = n_distinct(patient)
  )


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
  geom_jitter(alpha = .6, width = .5, height = 0) +
  theme(legend.position = "none") +
  labs(
    title = "Verdeling behandeltijden per kamerType",
    #subtitle = "",
    x = "Behandeltijd in minuten",
    y = NULL
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
  scale_x_continuous(labels = scales::number_format()) +
  theme(legend.position = "none") +
  #scale_x_log10() +
  labs(
    title = "Verdeling wachttijden per kamerType",
    #subtitle = "",
    x = "Wachttijd in minuten",
    y = NULL
  )

events_wrangle |>
  filter(
    resource %in%
      c(
        "Reception",
        "Pharmacy",
        "General Diagnosis Room",
        "Operating Theatre",
        "Electrolysis"
      )
  ) |>
  ggplot(aes(x = waitTime, fill = startTimeMonth)) +
  geom_histogram() +
  facet_wrap(~resource, ncol = 1, scales = "free_y") +
  scale_x_continuous(labels = scales::number_format())

# Benutting ---------------
# wat voor data heb ik nodig om dit te gaan berekenen?
# starttijd dat kamer in behandeling is + eindtijd -> geeft blokken van benutting.
# een totale tijd dat een behandelkamer beschibaar is (openingstijden)

tabel_benutting <- events_wrangle |>
  group_by(resource, startTimeMonth) |>
  summarise(
    sumWaitTime = sum(waitTime),
    avgWaitTime = mean(waitTime),
    medianWaitTime = median(waitTime),
    sumActivityTime = sum(activityTime),
    avgActivityTime = mean(activityTime),
    medianActivityTime = median(activityTime)
  ) |>
  left_join(
    resource_definitie |>
      transmute(resource = resourceName, capacity),
    by = "resource"
  ) |>
  mutate(
    # Noemer = enkel de werkuren dat een resource beschikbaar is (niet 24/7)
    potentialActivityTime = capacity * simDays * workDayMinutes,
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

# Maandelijkse aggregaties -------------

events_wrangle |>
  group_by(
    startTimeMonth
  ) |>
  summarise(
    patienten = n_distinct(name),
    maxWaitTime = max(waitTime),
    avgWaitTime = mean(waitTime),
    medianWaitTime = median(waitTime),
    maxActivityTime = max(activityTime),
    avgActivityTime = mean(activityTime),
    medianActivityTime = median(activityTime),
  )

log_aankomst_ontslag |>
  group_by(
    aankomstTijdstipMonth,
    aandoeningOmschrijving
  ) |>
  summarise(
    patienten = n_distinct(patient)
  ) |>
  pivot_wider(names_from = aankomstTijdstipMonth, values_from = patienten) |>
  View()
