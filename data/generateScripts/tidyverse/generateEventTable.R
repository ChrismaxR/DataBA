library(tidyverse)
library(lubridate)

source("data/generateScripts/utils.R")

openStartTime <- min(tijd_vector)
openEndTime <- max(tijd_vector)

openStamp <- function(dateValue, timeString) {
  as.POSIXct(paste(dateValue, timeString), tz = "UTC")
}

ensureWithinOpening <- function(timePoint, duration) {
  current <- timePoint
  repeat {
    openStart <- openStamp(as.Date(current, tz = "UTC"), openStartTime)
    openEnd <- openStamp(as.Date(current, tz = "UTC"), openEndTime)

    if (current < openStart) {
      current <- openStart
    }

    if (current + duration <= openEnd) {
      return(current)
    }

    nextDate <- as.Date(current, tz = "UTC") + days(1)
    current <- openStamp(nextDate, openStartTime)
  }
}

getNextAvailableStart <- function(candidate, duration, roomBlocks) {
  current <- candidate
  repeat {
    current <- ensureWithinOpening(current, duration)

    if (is.null(roomBlocks) || nrow(roomBlocks) == 0) {
      return(current)
    }

    overlap_idx <- which(roomBlocks$start < current + duration &
      roomBlocks$end > current)

    if (length(overlap_idx) == 0) {
      return(current)
    }

    overlap <- roomBlocks[overlap_idx[which.min(roomBlocks$start[overlap_idx])], ]
    current <- overlap$end
  }
}

sampleArrivalDateTimes <- function(n) {
  dates <- sample(datum_vector, n, replace = TRUE)
  times <- sample(tijd_vector, n, replace = TRUE)
  as.POSIXct(paste(dates, times), tz = "UTC")
}

buildRoomBlocks <- function(
  rooms,
  dates = datum_vector,
  breaksPerDay = 2,
  breakMinutes = 30,
  machineLambda = 2,
  ontslagProb = 0.02
) {
  timeSeconds <- period_to_seconds(hms(tijd_vector))
  endSeconds <- period_to_seconds(hms(openEndTime))
  breakStartCutoff <- endSeconds - breakMinutes * 60
  breakTimes <- tijd_vector[timeSeconds <= breakStartCutoff]

  breakBlocks <- tidyr::expand_grid(
    kamerId = rooms$kamerId,
    kamerTypeId = rooms$kamerTypeId,
    date = dates,
    breakIndex = seq_len(breaksPerDay)
  ) |>
    mutate(
      startTime = sample(breakTimes, n(), replace = TRUE),
      start = as.POSIXct(paste(date, startTime), tz = "UTC"),
      end = start + minutes(breakMinutes),
      eventType = "staffMetPauze"
    ) |>
    select(kamerId, kamerTypeId, eventType, start, end)

  machineBlocks <- rooms |>
    filter(maxDuratieMankement > 0) |>
    mutate(nEvents = rpois(n(), lambda = machineLambda)) |>
    filter(nEvents > 0) |>
    uncount(nEvents) |>
    mutate(
      date = sample(dates, n(), replace = TRUE),
      startTime = sample(tijd_vector, n(), replace = TRUE),
      start = as.POSIXct(paste(date, startTime), tz = "UTC"),
      duration = map_int(maxDuratieMankement, ~ sample(5:.x, 1)),
      end = start + minutes(duration),
      eventType = "machineKapot"
    ) |>
    select(kamerId, kamerTypeId, eventType, start, end)

  ontslagBlocks <- rooms |>
    mutate(trigger = rbinom(n(), 1, ontslagProb)) |>
    filter(trigger == 1) |>
    mutate(
      date = sample(dates, n(), replace = TRUE),
      startTime = sample(tijd_vector, n(), replace = TRUE),
      start = as.POSIXct(paste(date, startTime), tz = "UTC"),
      end = start + days(2),
      eventType = "staffOntslagGenomen"
    ) |>
    select(kamerId, kamerTypeId, eventType, start, end)

  bind_rows(breakBlocks, machineBlocks, ontslagBlocks) |>
    arrange(kamerId, start)
}

makeEvent <- function(
  eventType,
  datumTijd,
  patientId = NA_integer_,
  kamerId = NA_integer_,
  kamerTypeId = NA_integer_
) {
  tibble::tibble(
    eventType = eventType,
    datumTijd = datumTijd,
    patientId = patientId,
    kamerId = kamerId,
    kamerTypeId = kamerTypeId
  )
}

bookRoom <- function(roomTypeId, readyTime, roomState, roomBlocksById) {
  candidates <- roomState |>
    filter(kamerTypeId == roomTypeId) |>
    slice_min(volgendeVrijeDatumTijd, with_ties = FALSE)

  if (nrow(candidates) == 0) {
    stop("No rooms found for kamerTypeId: ", roomTypeId)
  }

  roomRow <- candidates[1, ]
  durationMinutes <- sample(
    roomRow$minDuratieKamer:roomRow$maxDuratieKamer,
    1
  )
  duration <- minutes(durationMinutes)
  candidateStart <- max(readyTime, roomRow$volgendeVrijeDatumTijd)
  roomBlocks <- roomBlocksById[[as.character(roomRow$kamerId)]]
  start <- getNextAvailableStart(candidateStart, duration, roomBlocks)
  end <- start + duration

  roomState$volgendeVrijeDatumTijd[
    roomState$kamerId == roomRow$kamerId
  ] <- end

  list(
    room = roomRow,
    start = start,
    end = end,
    roomState = roomState
  )
}

buildPatientEvents <- function(patientRow, roomState, roomBlocksById) {
  pid <- patientRow$patientId
  arrival <- patientRow$aankomstDatumTijd
  events <- list(
    makeEvent("aankomst", arrival, pid),
    makeEvent("inWachtrijReceptie", arrival, pid, kamerTypeId = 1L)
  )

  reception <- bookRoom(1L, arrival, roomState, roomBlocksById)
  roomState <- reception$roomState
  events <- append(events, list(
    makeEvent(
      "inReceptie",
      reception$start,
      pid,
      reception$room$kamerId,
      1L
    ),
    makeEvent(
      "inGebruik",
      reception$start,
      pid,
      reception$room$kamerId,
      1L
    ),
    makeEvent("vrij", reception$end, NA_integer_, reception$room$kamerId, 1L)
  ))

  events <- append(events, list(
    makeEvent(
      "inWachtrijDiagnose",
      reception$end,
      pid,
      kamerTypeId = patientRow$diagnoseKamerTypeId
    )
  ))

  diagnosis <- bookRoom(
    patientRow$diagnoseKamerTypeId,
    reception$end,
    roomState,
    roomBlocksById
  )
  roomState <- diagnosis$roomState
  events <- append(events, list(
    makeEvent(
      "inDiagnose",
      diagnosis$start,
      pid,
      diagnosis$room$kamerId,
      patientRow$diagnoseKamerTypeId
    ),
    makeEvent(
      "inGebruik",
      diagnosis$start,
      pid,
      diagnosis$room$kamerId,
      patientRow$diagnoseKamerTypeId
    ),
    makeEvent(
      "vrij",
      diagnosis$end,
      NA_integer_,
      diagnosis$room$kamerId,
      patientRow$diagnoseKamerTypeId
    )
  ))

  events <- append(events, list(
    makeEvent(
      "inWachtrijBehandeling",
      diagnosis$end,
      pid,
      kamerTypeId = patientRow$behandelKamerTypeId
    )
  ))

  treatment <- bookRoom(
    patientRow$behandelKamerTypeId,
    diagnosis$end,
    roomState,
    roomBlocksById
  )
  roomState <- treatment$roomState
  events <- append(events, list(
    makeEvent(
      "inBehandeling",
      treatment$start,
      pid,
      treatment$room$kamerId,
      patientRow$behandelKamerTypeId
    ),
    makeEvent(
      "inGebruik",
      treatment$start,
      pid,
      treatment$room$kamerId,
      patientRow$behandelKamerTypeId
    ),
    makeEvent(
      "vrij",
      treatment$end,
      NA_integer_,
      treatment$room$kamerId,
      patientRow$behandelKamerTypeId
    )
  ))

  if (patientRow$patientScenario == "foutieveDiagnose") {
    newDiagType <- coalesce(
      patientRow$juisteDiagnoseKamerId,
      patientRow$diagnoseKamerTypeId
    )
    newTreatType <- coalesce(
      patientRow$juisteBehandelKamerId,
      patientRow$behandelKamerTypeId
    )

    events <- append(events, list(
      makeEvent(
        "inWachtrijNieuweDiagnose",
        treatment$end,
        pid,
        kamerTypeId = newDiagType
      )
    ))

    newDiagnosis <- bookRoom(
      newDiagType,
      treatment$end,
      roomState,
      roomBlocksById
    )
    roomState <- newDiagnosis$roomState
    events <- append(events, list(
      makeEvent(
        "inNieuweDiagnose",
        newDiagnosis$start,
        pid,
        newDiagnosis$room$kamerId,
        newDiagType
      ),
      makeEvent(
        "inGebruik",
        newDiagnosis$start,
        pid,
        newDiagnosis$room$kamerId,
        newDiagType
      ),
      makeEvent(
        "vrij",
        newDiagnosis$end,
        NA_integer_,
        newDiagnosis$room$kamerId,
        newDiagType
      )
    ))

    events <- append(events, list(
      makeEvent(
        "inWachtrijNieuweBehandeling",
        newDiagnosis$end,
        pid,
        kamerTypeId = newTreatType
      )
    ))

    newTreatment <- bookRoom(
      newTreatType,
      newDiagnosis$end,
      roomState,
      roomBlocksById
    )
    roomState <- newTreatment$roomState
    events <- append(events, list(
      makeEvent(
        "inNieuweBehandeling",
        newTreatment$start,
        pid,
        newTreatment$room$kamerId,
        newTreatType
      ),
      makeEvent(
        "inGebruik",
        newTreatment$start,
        pid,
        newTreatment$room$kamerId,
        newTreatType
      ),
      makeEvent(
        "ontslagen",
        newTreatment$end,
        pid,
        newTreatment$room$kamerId,
        newTreatType
      ),
      makeEvent(
        "vrij",
        newTreatment$end,
        NA_integer_,
        newTreatment$room$kamerId,
        newTreatType
      )
    ))
  } else {
    events <- append(events, list(
      makeEvent(
        "ontslagen",
        treatment$end,
        pid,
        treatment$room$kamerId,
        patientRow$behandelKamerTypeId
      )
    ))
  }

  list(events = bind_rows(events), roomState = roomState)
}

generateEventTable <- function(
  writeCsv = FALSE,
  outPath = "data/fct_event.csv",
  breaksPerDay = 2,
  breakMinutes = 30,
  machineLambda = 2,
  ontslagProb = 0.02
) {
  patienten <- patientenStamTabel |>
    mutate(aankomstDatumTijd = sampleArrivalDateTimes(n())) |>
    arrange(aankomstDatumTijd)

  roomState <- kamerDimensies |>
    mutate(
      volgendeVrijeDatumTijd = pmax(
        volgendeVrijeDatumTijd,
        openStamp(min(datum_vector), openStartTime)
      )
    )

  roomBlocks <- buildRoomBlocks(
    roomState,
    dates = datum_vector,
    breaksPerDay = breaksPerDay,
    breakMinutes = breakMinutes,
    machineLambda = machineLambda,
    ontslagProb = ontslagProb
  )
  roomBlocksById <- split(roomBlocks, roomBlocks$kamerId)

  eventRows <- vector("list", nrow(patienten))
  for (i in seq_len(nrow(patienten))) {
    result <- buildPatientEvents(patienten[i, ], roomState, roomBlocksById)
    roomState <- result$roomState
    eventRows[[i]] <- result$events
  }

  patientEvents <- bind_rows(eventRows)
  roomEvents <- bind_rows(
    roomBlocks |>
      transmute(
        eventType,
        datumTijd = start,
        patientId = NA_integer_,
        kamerId,
        kamerTypeId
      ),
    roomBlocks |>
      transmute(
        eventType = "vrij",
        datumTijd = end,
        patientId = NA_integer_,
        kamerId,
        kamerTypeId
      )
  )

  eventTable <- bind_rows(patientEvents, roomEvents) |>
    arrange(datumTijd, patientId, kamerId, eventType) |>
    mutate(eventId = row_number(), .before = eventType)

  if (writeCsv) {
    readr::write_csv(eventTable, outPath)
  }

  eventTable
}

# Example:
tictoc::tic()
events <- generateEventTable(writeCsv = F)
tictoc::toc()
