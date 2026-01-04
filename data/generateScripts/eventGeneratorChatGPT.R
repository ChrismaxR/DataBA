library(tidyverse)
library(lubridate)

# pull in patient base (incl. routes) and dimensions
source("data/generateScripts/utils.R")
source("data/generateScripts/dim_kamerType.R")

# scenario tuning per docs/story5.md (controls waits and room availability by difficulty)
scenario_params <- tribble(
  ~scenario    , ~wait_diag_min , ~wait_diag_max , ~wait_treat_min , ~wait_treat_max , ~availability ,
  "Easy"       ,              0 ,              1 ,               0 ,               1 , 1.00          ,
  "Medium"     ,              0 ,             10 ,               0 ,              10 , 0.90          ,
  "Hard"       ,              5 ,             25 ,               5 ,              25 , 0.75          ,
  "Ultra hard" ,              5 ,             25 ,               5 ,              25 , 0.50
)

# room pool with counts per kamerTypeId (tweak counts to model capacity)
rooms <- dim_kamerType |>
  mutate(
    kamer_count = c(
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
  uncount(kamer_count, .remove = FALSE, .id = "room_seq") |>
  mutate(
    kamer_id = row_number(),
    kamerTypeId = id,
    next_free = as.POSIXct("2025-01-01 00:00:00", tz = "UTC") # tracks when a specific room frees up
  ) |>
  select(kamer_id, kamerTypeId, kamerType, next_free)

# Draw random arrival datetimes by sampling date and time separately
sample_arrival <- function(n) {
  as.POSIXct(sample(datum_vector, n, replace = TRUE), tz = "UTC") +
    hms(sample(tijd_vector, n, replace = TRUE))
}

# After a booking ends, sometimes delay the room's next_free to mimic overruns/breaks
apply_availability <- function(time_point, availability) {
  if (runif(1) > availability) {
    time_point + dminutes(sample(15:45, 1))
  } else {
    time_point
  }
}

# Build the ordered event trace for a single patient and update room schedule
generate_patient_events <- function(p_row, rooms_state) {
  scen <- scenario_params |> filter(scenario == p_row$scenario)

  rec_dur <- dminutes(12)
  diag_dur <- dminutes(sample(20:30, 1))
  treat_dur <- dminutes(sample(40:60, 1))

  wait_diag <- dminutes(runif(1, scen$wait_diag_min, scen$wait_diag_max))
  wait_treat <- dminutes(runif(1, scen$wait_treat_min, scen$wait_treat_max))

  t_rec <- p_row$arrival_dt
  t_rec_end <- t_rec + rec_dur

  # allocate the earliest-available diagnosis room of the required type
  diag_room <- rooms_state |>
    filter(kamerTypeId == p_row$diagnoseKamerId) |>
    slice_min(next_free, with_ties = FALSE)

  t_diag_start <- max(t_rec_end, diag_room$next_free) + wait_diag
  t_diag_end <- t_diag_start + diag_dur

  # allocate the earliest-available treatment room of the required type
  treat_room <- rooms_state |>
    filter(kamerTypeId == p_row$behandelKamerId) |>
    slice_min(next_free, with_ties = FALSE)

  t_treat_start <- max(t_diag_end, treat_room$next_free) + wait_treat
  t_treat_end <- t_treat_start + treat_dur

  events <- tribble(
    ~event_type            , ~datumTijd                 , ~patientId      , ~kamerId            , ~kamerTypeId          ,
    "WachtenOpReceptie"    , t_rec                      , p_row$patientId , NA_integer_         , 1L                    ,
    "InReceptie"           , t_rec                      , p_row$patientId , NA_integer_         , 1L                    ,
    "WachtenOpDiagnose"    , t_diag_start - wait_diag   , p_row$patientId , NA_integer_         , p_row$diagnoseKamerId ,
    "InDiagnose"           , t_diag_start               , p_row$patientId , diag_room$kamer_id  , p_row$diagnoseKamerId ,
    "WachtenOpBehandeling" , t_treat_start - wait_treat , p_row$patientId , NA_integer_         , p_row$behandelKamerId ,
    "InBehandeling"        , t_treat_start              , p_row$patientId , treat_room$kamer_id , p_row$behandelKamerId ,
    "Ontslagen"            , t_treat_end                , p_row$patientId , treat_room$kamer_id , p_row$behandelKamerId
  )

  rooms_state$next_free[
    rooms_state$kamer_id == diag_room$kamer_id
  ] <- apply_availability(t_diag_end, scen$availability)
  rooms_state$next_free[
    rooms_state$kamer_id == treat_room$kamer_id
  ] <- apply_availability(t_treat_end, scen$availability)

  list(events = events, rooms_state = rooms_state)
}

# Simulate events for all patients, optionally persisting the fact table
generate_fct_event <- function(
  write_csv = FALSE,
  out_path = "data/fct_event.csv"
) {
  patienten_ext <- patienten |>
    mutate(arrival_dt = sample_arrival(n())) |>
    arrange(arrival_dt)

  rooms_state <- rooms
  event_rows <- vector("list", nrow(patienten_ext))

  for (i in seq_len(nrow(patienten_ext))) {
    res <- generate_patient_events(patienten_ext[i, ], rooms_state)
    rooms_state <- res$rooms_state
    event_rows[[i]] <- res$events
  }

  fct_event <- bind_rows(event_rows) |>
    arrange(datumTijd, patientId, event_type) |>
    mutate(event_id = row_number(), .before = event_type)

  if (write_csv) {
    readr::write_csv(fct_event, out_path)
  }

  fct_event
}

# Example: create tibble and write it out
tictoc::tic()
fct_event_tbl <- generate_fct_event(write_csv = F)
tictoc::toc()
