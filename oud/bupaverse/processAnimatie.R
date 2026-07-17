# processAnimatie.R
# Animates patient trajectories through hospital resources using processanimateR.
#
# Output: data/statsScripts/bupaverse/processAnimatie.html
# Run:    Rscript data/statsScripts/bupaverse/processAnimatie.R
#         or source() interactively in RStudio (opens in Viewer pane).

library(bupaverse)
library(processanimateR)
library(dplyr)
library(readr)
library(lubridate)
library(tidyr)
library(htmlwidgets)

# ── Config ────────────────────────────────────────────────────────────────────

# Start small: 2 patients. Increase N_PATIENTS once rendering is confirmed.
N_PATIENTS <- 15
SEED <- 42
OUTPUT_HTML <- "data/statsScripts/bupaverse/processAnimatie.html"

# ── Read latest events_wrangle ────────────────────────────────────────────────

events_file <- list.files(
  "output/",
  pattern = "_events_wrangle\\.csv$",
  full.names = TRUE
) |>
  sort(decreasing = TRUE) |>
  first()

events_raw <- read_csv(events_file, show_col_types = FALSE)

# ── Pick the first N patients from the run ────────────────────────────────────

set.seed(SEED)
patient_ids <- events_raw |>
  distinct(name) |>
  slice_head(n = N_PATIENTS) |>
  pull(name)

message("Patienten: ", paste(patient_ids, collapse = ", "))

# ── Build a minimal long-format event table ───────────────────────────────────
#
# eventlog() requires one row per lifecycle event (start + complete).
# Select ONLY the four columns needed before pivoting — extra columns attached
# to the dataframe are interpreted as case/activity attributes and bloat the
# process map graph beyond what viz.js can render.

events_long <- events_raw |>
  filter(name %in% patient_ids) |>
  select(name, resource, startTimeReal, endTimeReal) |> # <-- critical: drop all extras
  mutate(
    startTimeReal = as_datetime(startTimeReal),
    endTimeReal = as_datetime(endTimeReal),
    activity_instance_id = row_number()
  ) |>
  pivot_longer(
    cols = c(startTimeReal, endTimeReal),
    names_to = "lifecycle",
    values_to = "timestamp"
  ) |>
  mutate(
    lifecycle = if_else(lifecycle == "startTimeReal", "start", "complete")
  )

# ── Create bupaR eventlog ─────────────────────────────────────────────────────

log_bupar <- events_long |>
  eventlog(
    case_id = "name",
    activity_id = "resource",
    activity_instance_id = "activity_instance_id",
    lifecycle_id = "lifecycle",
    timestamp = "timestamp",
    resource_id = "resource"
  )

# ── Animate ───────────────────────────────────────────────────────────────────

anim <- animate_process(
  log_bupar,
  mode = "absolute",
  jitter = 10
)

# ── Save & display ────────────────────────────────────────────────────────────

saveWidget(anim, file = OUTPUT_HTML, selfcontained = TRUE)
message("Animatie opgeslagen: ", OUTPUT_HTML)

anim
