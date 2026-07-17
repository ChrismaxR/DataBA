library(tidyverse)
library(lubridate)

# load event log (defaults to generated CSV)
load_eventlog <- function(path = "data/fct_event.csv") {
  readr::read_csv(path, show_col_types = FALSE) |>
    mutate(datumTijd = ymd_hms(datumTijd, tz = "UTC"))
}

# waiting time per month per roomType (diagnose + behandeling)
wait_snapshot <- function(events) {
  wait_calc <- function(df, wait_col, start_col) {
    df |>
      select(patientId, kamerTypeId, event_type, datumTijd) |>
      pivot_wider(names_from = event_type, values_from = datumTijd) |>
      mutate(
        wait_mins = as.numeric(difftime(
          .data[[start_col]],
          .data[[wait_col]],
          units = "mins"
        ))
      ) |>
      mutate(month = floor_date(.data[[start_col]], "month")) |>
      filter(!is.na(wait_mins), wait_mins >= 0)
  }

  diag_waits <- events |>
    filter(event_type %in% c("WachtenOpDiagnose", "InDiagnose")) |>
    wait_calc("WachtenOpDiagnose", "InDiagnose")

  treat_waits <- events |>
    filter(event_type %in% c("WachtenOpBehandeling", "InBehandeling")) |>
    wait_calc("WachtenOpBehandeling", "InBehandeling")

  bind_rows(
    diag_waits |>
      mutate(wait_stage = "Diagnose"),
    treat_waits |>
      mutate(wait_stage = "Behandeling")
  ) |>
    group_by(month, kamerTypeId, wait_stage) |>
    summarise(
      n = n(),
      wait_mean = mean(wait_mins, na.rm = TRUE),
      wait_p50 = median(wait_mins, na.rm = TRUE),
      wait_p95 = quantile(wait_mins, 0.95, na.rm = TRUE),
      .groups = "drop"
    )
}

# utilization per month per kamerId and per kamerTypeId (approximated)
util_snapshot <- function(
  events,
  diag_duration_minutes = 25,
  open_hours_per_day = as.numeric(difftime(
    as.POSIXct("2000-01-01 21:00:00"),
    as.POSIXct("2000-01-01 08:45:00"),
    units = "hours"
  ))
) {
  diag_intervals <- events |>
    filter(event_type == "InDiagnose", !is.na(kamerId)) |>
    transmute(
      kamerId,
      kamerTypeId,
      start = datumTijd,
      end = datumTijd + dminutes(diag_duration_minutes)
    )

  treat_intervals <- events |>
    filter(event_type %in% c("InBehandeling", "Ontslagen"), !is.na(kamerId)) |>
    select(patientId, kamerId, kamerTypeId, event_type, datumTijd) |>
    pivot_wider(names_from = event_type, values_from = datumTijd) |>
    filter(!is.na(InBehandeling)) |>
    transmute(
      kamerId,
      kamerTypeId,
      start = InBehandeling,
      end = coalesce(Ontslagen, InBehandeling)
    )

  intervals <- bind_rows(diag_intervals, treat_intervals) |>
    filter(end >= start) |>
    mutate(
      month = floor_date(start, "month"),
      busy_hours = as.numeric(difftime(end, start, units = "hours"))
    )

  busy_room_month <- intervals |>
    group_by(month, kamerId, kamerTypeId) |>
    summarise(busy_hours = sum(busy_hours, na.rm = TRUE), .groups = "drop")

  room_month_capacity <- busy_room_month |>
    mutate(
      days_in_month = lubridate::days_in_month(month),
      capacity_hours = days_in_month * open_hours_per_day,
      utilization = pmin(1, busy_hours / capacity_hours)
    )

  roomtype_month <- room_month_capacity |>
    group_by(month, kamerTypeId) |>
    summarise(
      busy_hours = sum(busy_hours, na.rm = TRUE),
      capacity_hours = sum(capacity_hours, na.rm = TRUE),
      utilization = busy_hours / capacity_hours,
      .groups = "drop"
    )

  list(per_room = room_month_capacity, per_roomtype = roomtype_month)
}

# Convenience: run both snapshots and optionally write to disk
generate_snapshots <- function(
  event_path = "data/fct_event.csv",
  write_csv = FALSE,
  out_wait = "data/snapshot_wait.csv",
  out_util_room = "data/snapshot_util_room.csv",
  out_util_type = "data/snapshot_util_roomtype.csv"
) {
  events <- load_eventlog(event_path)
  wait <- wait_snapshot(events)
  util <- util_snapshot(events)

  if (write_csv) {
    readr::write_csv(wait, out_wait)
    readr::write_csv(util$per_room, out_util_room)
    readr::write_csv(util$per_roomtype, out_util_type)
  }

  list(
    wait = wait,
    util_room = util$per_room,
    util_roomtype = util$per_roomtype
  )
}

data <- generate_snapshots()

data$wait |> View()
