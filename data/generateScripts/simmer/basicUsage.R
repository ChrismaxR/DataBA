library(simmer)

set.seed(42)

env <- simmer("SuperDuperSim")
env

patient <- trajectory("patients' path") |>
  ## add an intake activity 
  seize("nurse", 1) |>
  timeout(function() rnorm(1, 15)) |>
  release("nurse", 1) |>
  ## add a consultation activity
  seize("doctor", 1) |>
  timeout(function() rnorm(1, 20)) |>
  release("doctor", 1) |>
  ## add a planning activity
  seize("administration", 1) |>
  timeout(function() rnorm(1, 5)) |>
  release("administration", 1)

env |>
  add_resource("nurse", 1) |>
  add_resource("doctor", 2) |>
  add_resource("administration", 1) |>
  add_generator("patient", patient, function() rnorm(1, 10, 2))

env |> 
  run(80) |> 
  now()

env |> peek(3)

env |>
  stepn() |> # 1 step
  print() |>
  stepn(3)    # 3 steps

env |> peek(Inf, verbose=TRUE)

env |> get_n_generated("patient")
env |> get_queue_count("doctor")
env |> get_queue_size("doctor")
