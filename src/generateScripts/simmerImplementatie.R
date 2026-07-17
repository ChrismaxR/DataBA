# Simmer R package voor event data
## Stap voor stap logica opbouwen om story 5 om te zetten in een simmer implementatie

library(simmer)
library(dplyr)
set.seed(42)

# configuratiesettings -------
source("src/generateScripts/simmerConfig.R")

# Gedeelde helper: zoek de huidige waarde op in een tijdschema op basis van now(env)
schema_opzoeken <- function(schema, kolom) {
    dag <- now(env) / dayMinutes
    rij <- max(which(schema$dag_van <= dag))
    schema[[kolom]][rij]
}

# Tijdsafhankelijke aandoeningsbepaling: epidemie als bellcurve, rest uniform
aandoeningBepaling <- function() {
    dag <- now(env) / dayMinutes
    gewichten <- rep(1, 33)
    gewichten[epidemie_aandoening_id] <- 1 +
        (epidemie_piek_gewicht - 1) *
            exp(-0.5 * ((dag - epidemie_piek_dag) / epidemie_sd_dagen)^2)
    sample(1L:33L, size = 1, prob = gewichten / sum(gewichten))
}

# Tijdsafhankelijke aankomstdistributie: rate per kwartaal uit aankomst_schema
aankomstDistributie <- function() {
    rexp(1, rate = schema_opzoeken(aankomst_schema, "rate"))
}

# 1) Simulatie-omgeving + resources ----------
resource_map <- setNames(resource_definitie$resourceName, resource_definitie$id)

resource_durations <- resource_definitie |>
    transmute(
        id,
        min = case_when(
            id == 1L ~ 5,
            id %in% c(2L, 3L) ~ 9,
            id %in% c(4L, 5L) ~ 11,
            id %in% c(6L, 7L) ~ 15,
            id %in% c(8L, 9L, 10L) ~ 25,
            id %in% c(11L, 12L) ~ 45,
            id %in% c(13L, 14L, 15L) ~ 55,
            TRUE ~ 60
        ),
        max = case_when(
            id == 1L ~ 10,
            id %in% c(2L, 3L) ~ 15,
            id %in% c(4L, 5L) ~ 17,
            id %in% c(6L, 7L) ~ 20,
            id %in% c(8L, 9L, 10L) ~ 35,
            id %in% c(11L, 12L) ~ 60,
            id %in% c(13L, 14L, 15L) ~ 75,
            TRUE ~ 80
        )
    )

resource_timeout <- function(resource_id) {
    resource_id <- as.integer(resource_id)
    duration_row <- resource_durations[resource_durations$id == resource_id, ]
    if (nrow(duration_row) != 1L) {
        stop("Onbekende resource id: ", resource_id)
    }

    min_dur <- duration_row$min[1]
    max_dur <- duration_row$max[1]

    function() {
        mul <- schema_opzoeken(service_schema, "multiplier")
        mean_dur <- (min_dur + max_dur) / 2 * mul
        sdlog <- 0.3
        meanlog <- log(mean_dur) - sdlog^2 / 2
        rlnorm(1, meanlog, sdlog)
    }
}

maak_work_schedule <- function(capacity) {
    schedule(
        timetable = c(0, workDayMinutes),
        values = c(capacity, 0),
        period = dayMinutes
    )
}

workday_remaining <- function() {
    t <- now(env) %% dayMinutes
    remaining <- workDayMinutes - t
    if (remaining < 0) {
        0
    } else {
        remaining
    }
}

minutes_until_next_day <- function() {
    t <- now(env) %% dayMinutes
    dayMinutes - t
}

service_step <- function(trj, resource_id, tag_prefix) {
    resource_name <- resource_map[[as.character(resource_id)]]
    loop_tag <- paste0(tag_prefix, "_loop")

    spillover_traj <- trajectory() |>
        release(resource_name, 1) |>
        timeout(function() minutes_until_next_day()) |>
        seize(resource_name, 1) |>
        rollback(loop_tag, times = Inf)

    trj |>
        seize(resource_name, 1) |>
        set_attribute(
            keys = "remaining_service",
            values = function() resource_timeout(resource_id)()
        ) |>
        set_attribute(
            keys = "service_chunk",
            values = function() {
                remaining <- get_attribute(env, "remaining_service")
                available <- workday_remaining()
                min(remaining, available)
            },
            tag = loop_tag
        ) |>
        timeout(function() get_attribute(env, "service_chunk")) |>
        set_attribute(
            keys = "remaining_service",
            values = function() {
                get_attribute(env, "remaining_service") -
                    get_attribute(env, "service_chunk")
            }
        ) |>
        branch(
            function() {
                remaining <- get_attribute(env, "remaining_service")
                if (remaining > 0) 1L else 0L
            },
            spillover_traj,
            continue = TRUE
        ) |>
        release(resource_name, 1)
}

env <- Reduce(
    function(env, i) {
        add_resource(
            env,
            name = resource_definitie$resourceName[i],
            capacity = maak_work_schedule(resource_definitie$capacity[i]),
            queue_size = Inf
        )
    },
    seq_len(nrow(resource_definitie)),
    init = simmer("hospital")
)

# 1b) Capaciteitsmanager: pas kamercapaciteit aan op geplande dagen ----------
maak_cap_generator <- function(res_naam, schema_res) {
    traj <- trajectory(paste0("cap_", res_naam)) |>
        set_capacity(
            res_naam,
            value = function() {
                dag <- round(now(env) / dayMinutes)
                schema_res$nieuwe_cap[which.min(abs(schema_res$dag - dag))]
            }
        )
    add_generator(
        env,
        name_prefix = paste0("cap_", res_naam, "_"),
        trajectory = traj,
        distribution = at(schema_res$dag * dayMinutes)
    )
}

for (res_naam in unique(capaciteit_schema$resourceName)) {
    env <- maak_cap_generator(
        res_naam,
        capaciteit_schema[capaciteit_schema$resourceName == res_naam, ]
    )
}

# 2) Patient subtrajectories ------------

maak_traject <- function(
    traject_naam,
    diagnose_resource_id,
    behandel_resource_id
) {
    trajectory(traject_naam) |>
        service_step(diagnose_resource_id, paste0(traject_naam, "_diagnose")) |>
        service_step(behandel_resource_id, paste0(traject_naam, "_behandeling"))
}

trajA <- maak_traject("A", 2L, 8L)
trajB <- maak_traject("B", 2L, 10L)
trajC <- maak_traject("C", 2L, 18L)
trajD <- maak_traject("D", 2L, 14L)
trajE <- maak_traject("E", 2L, 9L)
trajF <- maak_traject("F", 3L, 11L)
trajG <- maak_traject("G", 3L, 10L)
trajH <- maak_traject("H", 3L, 18L)
trajI <- maak_traject("I", 3L, 12L)
trajJ <- maak_traject("J", 3L, 16L)
trajK <- maak_traject("K", 4L, 17L)
trajL <- maak_traject("L", 7L, 17L)
trajM <- maak_traject("M", 7L, 11L)
trajN <- maak_traject("N", 7L, 10L)
trajO <- maak_traject("O", 7L, 20L)
trajP <- maak_traject("P", 5L, 19L)
trajQ <- maak_traject("Q", 5L, 10L)
trajR <- maak_traject("R", 6L, 10L)
trajS <- maak_traject("S", 6L, 13L)

aandoening_route <- tibble::tibble(
    aandoeningId = 1:33,
    route = c(
        "A",
        "A",
        "A",
        "B",
        "B",
        "B",
        "B",
        "C",
        "C",
        "D",
        "E",
        "E",
        "E",
        "F",
        "F",
        "F",
        "F",
        "G",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "L",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S"
    )
)

route_order <- c(
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S"
)

route_index <- function() {
    aandoening_id <- get_attribute(env, "aandoeningId")
    route <- aandoening_route$route[match(
        aandoening_id,
        aandoening_route$aandoeningId
    )]
    index <- match(route, route_order)
    if (is.na(index)) {
        0L
    } else {
        index
    }
}

# 3) Patient maintrajectory ------------

traj0 <- trajectory("0") |>
    log_("aankomstTijdstip") |>
    set_attribute(
        keys = "aandoeningId",
        values = aandoeningBepaling
    ) |>
    log_(function() {
        paste(
            "aandoeningId =",
            get_attribute(env, "aandoeningId")
        )
    })

traj0 <- service_step(traj0, 1L, "reception")

traj0 <- branch(
    traj0,
    route_index,
    trajA,
    trajB,
    trajC,
    trajD,
    trajE,
    trajF,
    trajG,
    trajH,
    trajI,
    trajJ,
    trajK,
    trajL,
    trajM,
    trajN,
    trajO,
    trajP,
    trajQ,
    trajR,
    trajS,
    continue = TRUE
) |>
    log_("ontslagTijdstip")

# 4) Generator: Sim runnen ----------
log_lines <- capture.output({
    env |>
        add_generator(
            name_prefix = "patient",
            trajectory = traj0,
            distribution = from_to(
                start_time = 0,
                stop_time = workDayMinutes,
                dist = aankomstDistributie,
                every = dayMinutes
            ),
            mon = 2
        ) |>
        run(until = simDuration)
})

# 5) Capture loglines ------------
# There isn’t a built‑in “log monitor” in simmer; log_() writes to stdout only.
# The usual workaround is to capture that output and parse it into a data frame.

# keep only log_ lines (format: "time: arrival: message")
log_lines <- log_lines[grepl("^\\d", log_lines)]

log_df <- tibble::tibble(
    time = as.numeric(sub(":.*", "", log_lines)),
    arrival = sub("^[^:]+: ([^:]+):.*$", "\\1", log_lines),
    message = sub("^[^:]+: [^:]+: ", "", log_lines)
)


# 5) Monitoring -------------
events <- get_mon_arrivals(env, per_resource = TRUE) |>
    janitor::clean_names(case = "small_camel") |>
    tibble()
attributes <- get_mon_attributes(env) |>
    janitor::clean_names(case = "small_camel") |>
    tibble()
resources <- get_mon_resources(env) |>
    janitor::clean_names(case = "small_camel") |>
    tibble()

# 6) Wrangle data -------------

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

# waitTime berekenen (maar nog niet zeker of dit de juiste manier is), factor maken van resources
# plus daadwerkelijke tijdstippen maken m.b.v. helper uit

# simmer registreert zelf niet welke fysieke server/kamer een aankomst bezette
# (get_mon_resources geeft enkel een aantal bezette servers per tijdstip terug).
# Deze functie herleidt dat achteraf per resource via interval scheduling:
# elke seize-release cyclus krijgt de laagst genummerde server die op dat
# moment vrij is, anders een nieuw servernummer.
# Tolerantie: bij een naadloze overdracht (server komt vrij op exact het
# moment dat de volgende aankomst wordt gezeisd) kunnen endTime en
# startTime + waitTime elkaar op double-precisieniveau net mislopen (andere
# afleiding, geen exacte bit-match), waardoor er ten onrechte een extra slot
# geopend werd. 1e-6 minuten ligt ver onder elk reeel wachttijdverschil.
kamer_tolerantie <- 1e-6

ken_kamerNummer_slots_toe <- function(df) {
    service_start <- df$startTime + df$waitTime
    volgorde <- order(service_start)
    vrij_vanaf <- numeric(0)
    kamerNummer <- integer(nrow(df))

    for (i in volgorde) {
        vrije_slot <- which(vrij_vanaf <= service_start[i] + kamer_tolerantie)[
            1
        ]
        if (is.na(vrije_slot)) {
            vrij_vanaf <- c(vrij_vanaf, df$endTime[i])
            vrije_slot <- length(vrij_vanaf)
        } else {
            vrij_vanaf[vrije_slot] <- df$endTime[i]
        }
        kamerNummer[i] <- vrije_slot
    }

    df$kamerNummer <- kamerNummer
    df
}

events_wrangle <- events |>
    left_join(patientAttributes, by = c("name" = "patient")) |>
    mutate(
        # waitTime = tijd in de wachtrij = totale verblijfstijd bij resource minus daadwerkelijke behandeltijd
        # (endTime - startTime) geeft de totale tijd, activityTime is de diensttijd -> verschil is wachttijd
        waitTime = (endTime - activityTime) - startTime,
        resource = factor(
            resource,
            levels = resource_definitie$resourceName
        ),
        startTimeReal = to_datetime(startTime),
        endTimeReal = to_datetime(endTime),
        startTimeMonth = month(startTimeReal, label = T),
        endTimeMonth = month(endTimeReal, label = T),
        acitivityMonth = month(endTimeReal - dminutes(activityTime))
    ) |>
    mutate(rijVolgorde = row_number()) |>
    group_by(resource) |>
    group_modify(~ ken_kamerNummer_slots_toe(.x)) |>
    ungroup() |>
    arrange(rijVolgorde) |>
    dplyr::select(-rijVolgorde) #simmmer heeft ook select function... da's niet best.
