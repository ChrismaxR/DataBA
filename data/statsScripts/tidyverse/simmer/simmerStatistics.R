library("ggplot2")
library("forcats")
source("data/generateScripts/simmer/simmerImplementatie.R")


# Wat wil ik berekenen?

# wachttijden: per datum (eigenlijk maand), aandoening, kamerType, scenario

# benutting: % van de tijd dat resource in gebruik is van potentieel
# per datum (eigenlijk maand), aandoening, kamerType, scenario

## Wachttijden
events |>
  filter(name %in% c("patient25", "patient88")) |>
  mutate(
    waitTime = (endTime - activityTime) - startTime # is dit de juiste berekening?
  ) |>
  group_by(name) |> # ook per resource breakdown doen ipv patient
  summarise(total_wait_time = sum(waitTime))


# EDA

# Hoe zien aankokmst tijdstippen er uit?
events |>
  mutate(
    startTime = to_datetime(startTime),
    resourse = factor(
      resource,
      levels = c(
        "Receptie",
        "The GP's office",
        "General Diagnosis Room",
        "The Ward",
        "Slack Tongue Clinic"
      )
    )
  ) |>
  #filter(resource == "Receptie") |>
  ggplot(aes(
    x = startTime,
    fill = fct_rev(fct_inorder(resource))
  )) +
  geom_histogram() +
  scale_x_datetime() +
  labs(
    title = "Verdeling Aankomsten per kamerType van patiënten in mijn simulatie",
    subtitle = "",
    y = "Aankomsten patiënten",
    fill = "Kamer"
  )

# Hoe ziet de verdeling van behandeltijden per kamerType eruit?
events |>
  ggplot(aes(
    x = fct_infreq(resource),
    y = activityTime,
    fill = resource
  )) +
  geom_boxplot() +
  geom_jitter(alpha = .6, width = .2, height = 0) +
  theme(legend.position = "none") +
  labs(
    title = "Verdeling behandeltijden per kamerType",
    subtitle = "",
    y = "Behandeltijd in minuten",
    x = NULL
  )


# Hoe ziet de verdeling van wachttijden per kamerType eruit?
events |>
  mutate(
    waitTime = (endTime - activityTime) - startTime # is dit de juiste berekening?
  ) |>
  ggplot(aes(
    x = forcats::fct_infreq(resource),
    y = waitTime,
    fill = resource
  )) +
  geom_boxplot() +
  geom_jitter(alpha = .6, width = .2, height = 0) +
  theme(legend.position = "none") +
  labs(
    title = "Verdeling wachttijden per kamerType",
    subtitle = "",
    y = "Behandeltijd in minuten",
    x = NULL
  )


# Benutting
# wat voor data heb ik nodig om dit te gaan berekenen?
# starttijd dat kamer in behandeling is + eindtijd -> geeft blokken van benutting.
# een totale tijd dat een behandelkamer beschibaar is (openingstijden)

resources |>
  distinct(resource, server) |>
  arrange(resource)


events |>
  group_by(resource) |>
  summarise(
    sumActivityTime = sum(activityTime)
  ) |>
  mutate(
    potentialActivityTime = case_when(
      # hoe maak ik dit dynamisch?
      resource == "Receptie" ~ 3 * 60 * 8,
      resource == "General Diagnosis Room" ~ 2 * 60 * 8,
      resource == "The GP's office" ~ 2 * 60 * 8,
      resource == "The Ward" ~ 3 * 60 * 8,
      resource == "Slack Tongue Clinic" ~ 1 * 60 * 8,
      T ~ -1
    ),
    utilization = sumActivityTime / potentialActivityTime
  )
