# Simmer R package voor event data
## Stap voor stap logica opbouwen om story 5 om te zetten in een simmer implementatie

library(simmer)
library(dplyr)
set.seed(42)

# configuratiesettings -------
source("data/generateScripts/simmer/simmerConfig.R")

# 1) Simulatie-omgeving + resources ----------
env <- simmer("hospital") |>
    add_resource(
        name = "Receptie",
        capacity = receptieCapaciteit,
        queue_size = Inf
    ) |>
    add_resource(
        name = "GP's office",
        capacity = gpOfficeCapaciteit,
        queue_size = Inf
    ) |>
    add_resource(
        name = "General Diagnosis Room",
        capacity = generalDiagnosisCapaciteit,
        queue_size = Inf
    ) |>
    add_resource(
        name = "The Ward",
        capacity = wardCapaciteit,
        queue_size = Inf
    ) |>
    add_resource(
        name = "Slack Tongue Clinic",
        capacity = slackTongueCapaciteit,
        queue_size = Inf
    )

# 2) Patient subtrajectories ------------

trajA <- trajectory("A") |>
    seize(resource = "GP's office", amount = 1) |>
    timeout(gpOfficeTimeoutDuratie) |>
    release(resource = "GP's office", amount = 1) |>
    seize(resource = "The Ward", amount = 1) |>
    timeout(wardTimeoutDuratie) |>
    release(resource = "The Ward", amount = 1) #|>
#log_("test")

trajB <- trajectory("B") |>
    seize("General Diagnosis Room", 1) |>
    timeout(generalDiagnosisTimeoutDuratie) |>
    release("General Diagnosis Room", 1) |>
    seize("Slack Tongue Clinic", 1) |>
    timeout(slackTongueTimeoutDuratie) |>
    release("Slack Tongue Clinic", 1)

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
    }) |>
    seize("Receptie", 1) |>
    timeout(receptieTimeoutDuratie) |> # minutes
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
    log_("ontslagTijdstip")

# 4) Generator: Sim runnen ----------
log_lines <- capture.output({
    env |>
        add_generator(
            name_prefix = "patient",
            trajectory = traj0,
            distribution = aankomstDistributie,
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
    janitor::clean_names(case = "small_camel")
attributes <- get_mon_attributes(env) |>
    janitor::clean_names(case = "small_camel")
resources <- get_mon_resources(env) |>
    janitor::clean_names(case = "small_camel")
