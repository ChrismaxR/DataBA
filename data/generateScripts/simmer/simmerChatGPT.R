# =========================================================
# simmer-based event generator (skeleton)
# in een keer door ChatGTP gegenereerd. Snap er de ballen van
# =========================================================
library(tidyverse)
library(simmer)

# source jouw config (zoals nu)
source("data/generateScripts/utils.R")

# -----------------------------
# 0) Tijd helpers
# -----------------------------
simOrigin <- as.POSIXct("2025-01-01 00:00:00", tz = "UTC")

asSimTime <- function(dt) as.numeric(difftime(dt, simOrigin, units = "mins"))
asDateTime <- function(t) simOrigin + as.difftime(t, units = "mins")

hospitalOpenHour <- 9
hospitalCloseHour <- 21

isWithinOpeningHours <- function(dt) {
  h <- as.integer(format(dt, "%H"))
  h >= hospitalOpenHour && h < hospitalCloseHour
}

nextOpeningTime <- function(dt) {
  # als binnen opening → dt; anders volgende dag 09:00
  if (isWithinOpeningHours(dt)) {
    return(dt)
  }
  d <- as.Date(dt)
  # als na sluiting: volgende dag; als voor opening: zelfde dag
  if (as.integer(format(dt, "%H")) >= hospitalCloseHour) {
    d <- d + 1
  }
  as.POSIXct(paste(d, sprintf("%02d:00:00", hospitalOpenHour)), tz = "UTC")
}

randDurMins <- function(minM, maxM) sample(seq(minM, maxM, by = 1), 1)

# -----------------------------
# 1) Event collector
# -----------------------------
makeCollector <- function() {
  env <- new.env(parent = emptyenv())
  env$rows <- list()
  env$push <- function(
    eventType,
    t,
    patientId = NA_integer_,
    kamerId = NA_integer_,
    kamerTypeId = NA_integer_
  ) {
    env$rows[[length(env$rows) + 1]] <- tibble(
      eventType = eventType,
      datumTijd = asDateTime(t),
      patientId = ifelse(is.na(patientId), NA_integer_, as.integer(patientId)),
      kamerId = ifelse(is.na(kamerId), NA_integer_, as.integer(kamerId)),
      kamerTypeId = ifelse(
        is.na(kamerTypeId),
        NA_integer_,
        as.integer(kamerTypeId)
      )
    )
  }
  env
}

finalizeEvents <- function(collector) {
  bind_rows(collector$rows) |>
    arrange(datumTijd, eventType) |>
    mutate(eventId = row_number()) |>
    select(eventId, eventType, datumTijd, patientId, kamerId, kamerTypeId)
}

# -----------------------------
# 2) Resources: 1 per kamerId
# -----------------------------
addRoomResources <- function(envSim, kamerDimensies) {
  # resource name convention
  # room_<kamerId>
  for (i in seq_len(nrow(kamerDimensies))) {
    rid <- kamerDimensies$kamerId[i]
    add_resource(envSim, paste0("room_", rid), capacity = 1, queue_size = Inf)
  }
  envSim
}

# KamerType → vector kamerId
roomMapByType <- function(kamerDimensies) {
  split(kamerDimensies$kamerId, kamerDimensies$kamerTypeId)
}

# kies “eerste beste” kamerId binnen type: laagste (queue + server)
chooseRoomId <- function(envSim, kamerIds) {
  stats <- lapply(kamerIds, function(id) {
    get_mon_resources(envSim) |> dplyr::filter(resource == paste0("room_", id))
  })
  # monitoring kan leeg zijn vroeg in sim → fallback: eerste
  if (length(stats) == 0) {
    return(kamerIds[[1]])
  }
  kamerIds[[1]]
}

# -----------------------------
# 3) Downtime processen per kamerId
#    - machineKapot (random, maxDuratieMankement)
#    - staffMetPauze (2x per dag 30 min)
#    - staffOntslagGenomen (zeldzaam, 2 dagen)
# -----------------------------
maintenanceTrajForRoom <- function(kamerRow, collector) {
  rid <- kamerRow$kamerId
  rtype <- kamerRow$kamerTypeId

  traj <- trajectory(paste0("maint_room_", rid)) |>
    # pauzes: simpel skeleton (deterministische triggers kun je verfijnen)
    timeout(function() sample(60:240, 1)) |>
    seize(paste0("room_", rid), amount = 1) |>
    set_attribute("dummy", 1) |>
    timeout(0) |>
    # log: staffMetPauze start
    handle_unfinished(function(env) {
      collector$push(
        "staffMetPauze",
        now(env),
        kamerId = rid,
        kamerTypeId = rtype
      )
      0
    }) |>
    timeout(30) |>
    release(paste0("room_", rid), amount = 1) |>
    handle_unfinished(function(env) {
      collector$push("vrij", now(env), kamerId = rid, kamerTypeId = rtype)
      0
    }) |>
    rollback(9, Inf)

  traj
}

addRoomDowntime <- function(envSim, kamerDimensies, collector) {
  # 1 maintenance generator per kamerId
  for (i in seq_len(nrow(kamerDimensies))) {
    row <- kamerDimensies[i, ]
    add_generator(
      envSim,
      name_prefix = paste0("maint_", row$kamerId),
      trajectory = maintenanceTrajForRoom(row, collector),
      distribution = at(0)
    ) # start direct; refine to schedule if you want
  }
  envSim
}

# -----------------------------
# 4) Patient flow: traject per patient
# -----------------------------
logStep <- function(
  eventType,
  patientId,
  kamerId = NA_integer_,
  kamerTypeId = NA_integer_,
  collector
) {
  # simmer hook
  function() 0 # placeholder; actual logging via handle_unfinished below
}

seizeRoomType <- function(envSim, roomMap, kamerTypeId) {
  # In skeleton kiezen we gewoon eerste kamerId van type.
  # Je kunt hier smarter: check availability via monitoring.
  roomMap[[as.character(kamerTypeId)]][[1]]
}

patientTrajectory <- function(patientRow, roomMap, kamerDimensies, collector) {
  pid <- patientRow$patientId

  # helper om kamerRow te pakken
  getRoomRow <- function(kamerId) {
    kamerDimensies |> filter(kamerId == !!kamerId) |> slice(1)
  }

  traj <- trajectory(paste0("patient_", pid)) |>
    # aankomst
    timeout(0) |>
    handle_unfinished(function(env) {
      collector$push("aankomst", now(env), patientId = pid)
      0
    }) |>
    handle_unfinished(function(env) {
      collector$push(
        "inWachtrijReceptie",
        now(env),
        patientId = pid,
        kamerTypeId = 1L
      )
      0
    })

  # Receptie (kamerTypeId = 1) → kies kamerId
  recId <- roomMap[["1"]][[1]]
  recRow <- getRoomRow(recId)
  recDur <- randDurMins(recRow$minDuratieKamer, recRow$maxDuratieKamer)

  traj <- traj |>
    seize(paste0("room_", recId), 1) |>
    handle_unfinished(function(env) {
      collector$push(
        "inReceptie",
        now(env),
        patientId = pid,
        kamerId = recId,
        kamerTypeId = 1L
      )
      0
    }) |>
    timeout(recDur) |>
    release(paste0("room_", recId), 1) |>
    handle_unfinished(function(env) {
      collector$push("vrij", now(env), kamerId = recId, kamerTypeId = 1L)
      0
    })

  # Diagnose
  diagType <- patientRow$diagnoseKamerTypeId
  diagId <- roomMap[[as.character(diagType)]][[1]]
  diagRow <- getRoomRow(diagId)
  diagDur <- randDurMins(diagRow$minDuratieKamer, diagRow$maxDuratieKamer)

  traj <- traj |>
    handle_unfinished(function(env) {
      collector$push(
        "inWachtrijDiagnose",
        now(env),
        patientId = pid,
        kamerTypeId = diagType
      )
      0
    }) |>
    seize(paste0("room_", diagId), 1) |>
    handle_unfinished(function(env) {
      collector$push(
        "inDiagnose",
        now(env),
        patientId = pid,
        kamerId = diagId,
        kamerTypeId = diagType
      )
      0
    }) |>
    handle_unfinished(function(env) {
      collector$push(
        "inGebruik",
        now(env),
        patientId = pid,
        kamerId = diagId,
        kamerTypeId = diagType
      )
      0
    }) |>
    timeout(diagDur) |>
    release(paste0("room_", diagId), 1) |>
    handle_unfinished(function(env) {
      collector$push("vrij", now(env), kamerId = diagId, kamerTypeId = diagType)
      0
    })

  # Behandeling
  treatType <- patientRow$behandelKamerTypeId
  treatId <- roomMap[[as.character(treatType)]][[1]]
  treatRow <- getRoomRow(treatId)
  treatDur <- randDurMins(treatRow$minDuratieKamer, treatRow$maxDuratieKamer)

  traj <- traj |>
    handle_unfinished(function(env) {
      collector$push(
        "inWachtrijBehandeling",
        now(env),
        patientId = pid,
        kamerTypeId = treatType
      )
      0
    }) |>
    seize(paste0("room_", treatId), 1) |>
    handle_unfinished(function(env) {
      collector$push(
        "inBehandeling",
        now(env),
        patientId = pid,
        kamerId = treatId,
        kamerTypeId = treatType
      )
      0
    }) |>
    handle_unfinished(function(env) {
      collector$push(
        "inGebruik",
        now(env),
        patientId = pid,
        kamerId = treatId,
        kamerTypeId = treatType
      )
      0
    }) |>
    timeout(treatDur)

  # foutieveDiagnose lus (1x max)
  if (patientRow$patientScenario == "foutieveDiagnose") {
    newDiagType <- patientRow$juisteDiagnoseKamerId
    newTreatType <- patientRow$juisteBehandelKamerId

    newDiagId <- roomMap[[as.character(newDiagType)]][[1]]
    newTreatId <- roomMap[[as.character(newTreatType)]][[1]]

    newDiagRow <- getRoomRow(newDiagId)
    newTreatRow <- getRoomRow(newTreatId)

    traj <- traj |>
      handle_unfinished(function(env) {
        collector$push(
          "inWachtrijNieuweDiagnose",
          now(env),
          patientId = pid,
          kamerId = treatId,
          kamerTypeId = treatType
        )
        0
      }) |>
      release(paste0("room_", treatId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "vrij",
          now(env),
          kamerId = treatId,
          kamerTypeId = treatType
        )
        0
      }) |>
      seize(paste0("room_", newDiagId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "inNieuweDiagnose",
          now(env),
          patientId = pid,
          kamerId = newDiagId,
          kamerTypeId = newDiagType
        )
        0
      }) |>
      timeout(randDurMins(
        newDiagRow$minDuratieKamer,
        newDiagRow$maxDuratieKamer
      )) |>
      release(paste0("room_", newDiagId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "vrij",
          now(env),
          kamerId = newDiagId,
          kamerTypeId = newDiagType
        )
        0
      }) |>
      handle_unfinished(function(env) {
        collector$push(
          "inWachtrijNieuweBehandeling",
          now(env),
          patientId = pid,
          kamerId = newDiagId,
          kamerTypeId = newDiagType
        )
        0
      }) |>
      seize(paste0("room_", newTreatId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "inNieuweBehandeling",
          now(env),
          patientId = pid,
          kamerId = newTreatId,
          kamerTypeId = newTreatType
        )
        0
      }) |>
      timeout(randDurMins(
        newTreatRow$minDuratieKamer,
        newTreatRow$maxDuratieKamer
      )) |>
      handle_unfinished(function(env) {
        collector$push(
          "ontslagen",
          now(env),
          patientId = pid,
          kamerId = newTreatId,
          kamerTypeId = newTreatType
        )
        0
      }) |>
      release(paste0("room_", newTreatId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "vrij",
          now(env),
          kamerId = newTreatId,
          kamerTypeId = newTreatType
        )
        0
      })
  } else {
    traj <- traj |>
      handle_unfinished(function(env) {
        collector$push(
          "ontslagen",
          now(env),
          patientId = pid,
          kamerId = treatId,
          kamerTypeId = treatType
        )
        0
      }) |>
      release(paste0("room_", treatId), 1) |>
      handle_unfinished(function(env) {
        collector$push(
          "vrij",
          now(env),
          kamerId = treatId,
          kamerTypeId = treatType
        )
        0
      })
  }

  traj
}

# -----------------------------
# 5) Arrivals scheduling (opening hours)
# -----------------------------
patientArrivalTime <- function(datum_vector, tijd_vector) {
  d <- sample(datum_vector, 1)
  t <- sample(tijd_vector, 1)
  dt <- as.POSIXct(paste(d, t), tz = "UTC")
  nextOpeningTime(dt)
}

buildArrivalSchedule <- function(
  patientenStamTabel,
  datum_vector,
  tijd_vector
) {
  # simmer 'at()' verwacht sim-tijden (mins)
  dts <- map(
    patientenStamTabel$patientId,
    ~ patientArrivalTime(datum_vector, tijd_vector)
  )
  times <- map_dbl(dts, asSimTime)
  times
}

# -----------------------------
# 6) Run
# -----------------------------
generateEventTableWithSimmer <- function(nPatients = 500) {
  pats <- patientenStamTabel |> slice_head(n = nPatients)

  collector <- makeCollector()
  envSim <- simmer("DataBA_hospital")

  roomMap <- roomMapByType(kamerDimensies)

  envSim <- addRoomResources(envSim, kamerDimensies)
  envSim <- addRoomDowntime(envSim, kamerDimensies, collector)

  arrivalTimes <- buildArrivalSchedule(pats, datum_vector, tijd_vector)

  # 1 generator per patiënt zodat trajectory per patiënt kan verschillen (scenario)
  for (i in seq_len(nrow(pats))) {
    prow <- pats[i, ]
    traj <- patientTrajectory(prow, roomMap, kamerDimensies, collector)
    add_generator(
      envSim,
      name_prefix = paste0("patient_", prow$patientId),
      trajectory = traj,
      distribution = at(arrivalTimes[i])
    )
  }

  run(envSim, until = asSimTime(as.POSIXct("2026-01-01 00:00:00", tz = "UTC")))

  finalizeEvents(collector)
}

# Voorbeeld:
eventTable <- generateEventTableWithSimmer(nPatients = 20)
glimpse(eventTable)
