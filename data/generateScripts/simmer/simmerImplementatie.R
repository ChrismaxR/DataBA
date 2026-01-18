# Simmer R package voor event data
## Stap voor stap logica opbouwen om story 5 om te zetten in een simmer implementatie

library(simmer)
library(dplyr)

set.seed(42)

# helperfuncties

sim_origin <- as.POSIXct("2025-01-01 09:00:00", tz = "UTC")

to_datetime <- function(t_minutes) {
    sim_origin + as.difftime(t_minutes, units = "mins")
}


# 1) Simulatie-omgeving + resources
env <- simmer("hospital") |>
    add_resource("Receptie", capacity = 3, queue_size = Inf) |>
    add_resource("The GP's office", capacity = 2, queue_size = Inf) |>
    add_resource("General Diagnosis Room", capacity = 2, queue_size = Inf) |>
    add_resource("The Ward", capacity = 2, queue_size = Inf) |>
    add_resource("Slack Tongue Clinic", capacity = 1, queue_size = Inf)

# 2) Patient subtrajectories

trajA <- trajectory("A") |>
    seize("The GP's office", 1) |>
    timeout(function() runif(1, 10, 20)) |>
    release("The GP's office", 1) |>
    seize("The Ward", 1) |>
    timeout(function() runif(1, 15, 30)) |>
    release("The Ward", 1)

trajB <- trajectory("B") |>
    seize("General Diagnosis Room", 1) |>
    timeout(function() runif(1, 10, 20)) |>
    release("General Diagnosis Room", 1) |>
    seize("Slack Tongue Clinic", 1) |>
    timeout(function() runif(1, 15, 30)) |>
    release("Slack Tongue Clinic", 1)

traj0 <- trajectory("0") |>
    set_attribute(keys = "aandoeningId", values = function() {
        sample(1L:2L, 1)
    }) |>
    log_(function() {
        paste(
            "Aankomst met aandoeningId = ",
            get_attribute(env, "aandoeningId")
        )
    }) |>
    seize("Receptie", 1) |>
    timeout(function() runif(1, 5, 10)) |> # minutes
    release("Receptie", 1) %>%
    branch(
        function() {
            r <- get_attribute(env, "aandoeningId")
            if (r %in% c(1)) {
                1L # -> traj_A
            } else if (r %in% c(2)) {
                2L # -> traj_B
            } else {
                3L # -> traj_C
            }
        },
        trajA,
        trajB,
        continue = TRUE
    ) |>
    log_(function() {
        paste("Ontslag met aandoeningId = ", get_attribute(env, "aandoeningId"))
    })

# 3) Generator: patiënten komen binnen (bv elke 3-8 minuten)
env |>
    add_generator(
        name_prefix = "patient",
        trajectory = traj0,
        distribution = function() runif(1, 1, 5),
        mon = 2
    ) |>
    run(until = 1 * 60) # aantal uur simulatie

# 5) Monitoring: wie zat wanneer op welke resource
get_mon_arrivals(env, per_resource = TRUE)
get_mon_attributes(env)
get_mon_resources(env)

# 6) Ombouwen van monitoring data naar event tabel
# NB get_mon_arrivals() geeft niet direct een queue time, dit moet ik berekenen:
# waiting_time_next_event = end_time_this_event - (start_time_this_event + activity_time_this_event)
# events <- events |>
#filter(name == "patient10") |>
#    transmute(
#        name,
#        resource,
#        start_time_this_event = start_time,
#        activity_time_this_event = activity_time,
#        end_time_this_event = end_time,
#        release_time_this_event = start_time_this_event +
#            activity_time_this_event,
#        wait_time_next_resource = end_time_this_event - release_time_this_event,
#        seize_time_next_resource = end_time
#        #patientId = as.integer(gsub("\\D+", "", name)),
#        #kamerType = resource,
#        #start_dt = to_datetime(start_time),
#        #end_dt = to_datetime(end_time),
#        #activity_time = difftime(end_dt, start_dt, units = "mins"),
#        #eventType = "inGebruik"
#    ) |>
#    # maak tabel long
#    tidyr::pivot_longer(cols = 3:7, names_repair = "minimal")
