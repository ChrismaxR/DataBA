# Simmer R package voor event data
## Stap voor stap logica opbouwen om story 5 om te zetten in een simmer implementatie

library(simmer)
library(dplyr)

set.seed(42)

# helpers

sim_origin <- as.POSIXct("2025-01-01 09:00:00", tz = "UTC")

to_datetime <- function(t_minutes) {
    sim_origin + as.difftime(t_minutes, units = "mins")
}


# 1) Simulatie-omgeving + resources
env <- simmer("hospital") |>
    add_resource("receptie", capacity = 3, queue_size = Inf) |>
    add_resource("diagnose", capacity = 2, queue_size = Inf) |>
    add_resource("behandeling", capacity = 1, queue_size = Inf)

# 2) Patiënt-traject (super simpel)
patient <- trajectory("patient") |>
    log_("aankomst") |>
    seize("receptie", 1) |>
    log_("inReceptie", level = 2) |>
    timeout(function() runif(1, 5, 10)) |> # minuten
    release("receptie", 1, ) |>
    log_("inWachtrijDiagnose") |>
    seize("diagnose", 1) |>
    timeout(function() runif(1, 10, 20)) |>
    release("diagnose", 1) |>
    log_("inWachtrijBehandeling") |>
    seize("behandeling", 1) |>
    timeout(function() runif(1, 15, 30)) |>
    release("behandeling", 1)

# 3) Generator: patiënten komen binnen (bv elke 3-8 minuten)
env |>
    add_generator(
        name_prefix = "patient",
        trajectory = patient,
        distribution = function() runif(1, 1, 2),
        mon = 2
    ) |>
    run(until = 8 * 60) # 2 uur simulatie

# 4) Monitoring: wie zat wanneer op welke resource
mon <- get_mon_arrivals(env, per_resource = TRUE)
mon_resources <- get_mon_resources(env)
attr_mon <- get_mon_attributes(env)

# 5) Jouw event-achtig formaat: start = inGebruik, end = vrij
service_events <- mon |>
    filter(name == "patient10") |>
    transmute(
        name,
        resource,
        start_time,
        activity_time,
        release_time = start_time + activity_time,
        wait_time_next_resource = end_time - release_time,
        seize_time_next_resource = end_time
        #patientId = as.integer(gsub("\\D+", "", name)),
        #kamerType = resource,
        #start_dt = to_datetime(start_time),
        #end_dt = to_datetime(end_time),
        #activity_time = difftime(end_dt, start_dt, units = "mins"),
        #eventType = "inGebruik"
    ) |>
    tidyr::pivot_longer(cols = 3:7, names_repair = "minimal")

mon_resources
