# monthlyAggregate.R
# ──────────────────────────────────────────────────────────────────────────────
# Leest alle gesimuleerde output CSVs uit output/ en aggregeert naar maandniveau.
# Schrijft drie bestanden naar output/aggregated/ voor het Evidence.dev dashboard.
#
# Volgorde in de pipeline:
#   simmerImplementatie.R → simmerStatistics.R → simmerWriteToDisk.R → dit script
#
# Drempel voor 'lang wachten': LANG_WACHTTIJD_DREMPEL (minuten)
# ──────────────────────────────────────────────────────────────────────────────

library(tidyverse)
library(lubridate)
library(here)

source(here("data/generateScripts/simmer/simmerConfig.R"))

LANG_WACHTTIJD_DREMPEL <- 60L  # minuten — grens voor n_lang_wachtend

# Maak output/aggregated/ aan als die nog niet bestaat
dir.create(here("output/aggregated"), showWarnings = FALSE, recursive = TRUE)


# ── Hulpfuncties ──────────────────────────────────────────────────────────────

# Extraheer jaar en maand als integers uit een ISO-tijdstempelkolom
voeg_jaar_maand_toe <- function(df, timestamp_kolom) {
  df |>
    mutate(
      ts    = ymd_hms(.data[[timestamp_kolom]], tz = "UTC"),
      jaar  = year(ts)  |> as.integer(),
      maand = month(ts) |> as.integer(),
      .keep = "unused"   # verwijder de hulpkolom ts achteraf
    )
}

# Aantal kalenderdagen in een gegeven jaar-maand combinatie
dagen_in_maand <- function(jaar, maand) {
  days_in_month(make_date(jaar, maand, 1L)) |> as.integer()
}


# ── Lookup-tabellen uit simmerConfig.R ───────────────────────────────────────

resource_lookup <- resource_definitie |>
  transmute(
    resource_id   = id,
    resource_naam = resourceName,
    capacity
  )


# ── 1. Lees alle events_wrangle CSVs ─────────────────────────────────────────

events_bestanden <- list.files(
  here("output"),
  pattern    = "^\\d{8}_events_wrangle\\.csv$",
  full.names = TRUE
)

if (length(events_bestanden) == 0L) stop("Geen events_wrangle CSV's gevonden in output/")
message("Events bestanden gevonden: ", length(events_bestanden))

events_raw <- events_bestanden |>
  map_dfr(read_csv, col_types = cols(.default = "c"), show_col_types = FALSE) |>
  mutate(
    waitTime     = as.double(waitTime),
    activityTime = as.double(activityTime)
  ) |>
  voeg_jaar_maand_toe("startTimeReal")


# ── 2. maandelijks_wachttijd ─────────────────────────────────────────────────
# Grain: resource × jaar × maand
# Bron: events_raw (events_wrangle)

maandelijks_wachttijd <- events_raw |>
  group_by(resource_naam = resource, jaar, maand) |>
  summarise(
    gem_wachttijd   = mean(waitTime),
    med_wachttijd   = median(waitTime),
    p95_wachttijd   = quantile(waitTime, 0.95),
    n_patienten     = n_distinct(name),
    n_lang_wachtend = sum(waitTime > LANG_WACHTTIJD_DREMPEL),
    .groups = "drop"
  ) |>
  left_join(resource_lookup |> select(resource_id, resource_naam), by = "resource_naam") |>
  select(
    resource_id, resource_naam, jaar, maand,
    gem_wachttijd, med_wachttijd, p95_wachttijd,
    n_patienten, n_lang_wachtend
  ) |>
  arrange(resource_id, jaar, maand)

write_csv(maandelijks_wachttijd, here("output/aggregated/maandelijks_wachttijd.csv"))
message("✓ maandelijks_wachttijd.csv — ", nrow(maandelijks_wachttijd), " rijen")


# ── 3. maandelijks_benutting ─────────────────────────────────────────────────
# Grain: resource × jaar × maand
# Noemer: capacity × werkdagminuten × kalenderdagen in die maand

maandelijks_benutting <- events_raw |>
  group_by(resource_naam = resource, jaar, maand) |>
  summarise(
    sumActivityTime = sum(activityTime),
    n_patienten     = n_distinct(name),
    .groups         = "drop"
  ) |>
  left_join(resource_lookup, by = "resource_naam") |>
  mutate(
    # Potentiële activiteitstijd = capacity × werkuren per dag × dagen in de maand
    maand_werkminuten = map2_int(jaar, maand, dagen_in_maand) * workDayMinutes,
    potentieel        = capacity * maand_werkminuten,
    bezettingsgraad   = if_else(
      potentieel > 0,
      sumActivityTime / potentieel,
      NA_real_
    )
  ) |>
  select(
    resource_id, resource_naam, jaar, maand,
    bezettingsgraad, n_patienten
  ) |>
  arrange(resource_id, jaar, maand)

write_csv(maandelijks_benutting, here("output/aggregated/maandelijks_benutting.csv"))
message("✓ maandelijks_benutting.csv — ", nrow(maandelijks_benutting), " rijen")


# ── 4. Lees alle log_aankomst_ontslag CSVs ───────────────────────────────────

log_bestanden <- list.files(
  here("output"),
  pattern    = "^\\d{8}_log_aankomst_ontslag\\.csv$",
  full.names = TRUE
)

if (length(log_bestanden) == 0L) stop("Geen log_aankomst_ontslag CSV's gevonden in output/")
message("Log bestanden gevonden: ", length(log_bestanden))

log_raw <- log_bestanden |>
  map_dfr(read_csv, col_types = cols(.default = "c"), show_col_types = FALSE) |>
  mutate(
    aandoening_id = as.integer(aandoeningId),
    # duratieInZiekenhuis bevat letterlijke "NA" strings voor niet-ontslagen patiënten
    duratieInZiekenhuis = na_if(duratieInZiekenhuis, "NA") |> as.double()
  ) |>
  voeg_jaar_maand_toe("aankomstTijdstipReal")


# ── 5. maandelijks_instroom ───────────────────────────────────────────────────
# Grain: aandoening × jaar × maand
# gem/med verblijfsduur: alleen over ontslagen patiënten (duratieInZiekenhuis niet NA)

maandelijks_instroom <- log_raw |>
  group_by(
    aandoening_id,
    aandoening = aandoeningOmschrijving,
    jaar,
    maand
  ) |>
  summarise(
    n_patienten       = n_distinct(patient),
    gem_verblijfsduur = mean(duratieInZiekenhuis,   na.rm = TRUE),
    med_verblijfsduur = median(duratieInZiekenhuis, na.rm = TRUE),
    .groups = "drop"
  ) |>
  select(
    aandoening_id, aandoening, jaar, maand,
    n_patienten, gem_verblijfsduur, med_verblijfsduur
  ) |>
  arrange(aandoening_id, jaar, maand)

write_csv(maandelijks_instroom, here("output/aggregated/maandelijks_instroom.csv"))
message("✓ maandelijks_instroom.csv — ", nrow(maandelijks_instroom), " rijen")


message("\nKlaar. Bestanden geschreven naar output/aggregated/")
