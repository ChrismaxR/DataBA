# Uitproberen van de simmer package om een beetje te begrijpen hoe dit deze werkt.
# Dient als input voor simmerImplementatie.R

library(simmer)
env <- simmer()

traj <- trajectory() %>%
  set_global("path", 1, mod = "+", init = -1) %>%
  log_(function() paste("Path", get_global(env, "path"), "selected")) %>%
  branch(
    function() get_global(env, "path"),
    continue = c(TRUE, FALSE),
    trajectory() %>%
      log_("following path 1"),
    trajectory() %>%
      log_("following path 2"),
    trajectory() |>
      log_("following path 3")
  ) %>%
  log_("continuing after the branch (path 0)")

env %>%
  add_generator("dummy", traj, at(0:3)) %>%
  run() %>%
  invisible
