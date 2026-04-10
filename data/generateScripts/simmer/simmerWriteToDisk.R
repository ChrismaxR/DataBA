source("data/statsScripts/simmer/simmerStatistics.R")
run_date <- Sys.Date()

# Visueel rapport naar disk ------------------
rapportFileName <- str_c(
  str_remove_all(as.character(Sys.Date()), "\\-"),
  "_simulatie_performance.png"
)

ggsave(
  plot = rapport,
  filename = rapportFileName,
  device = "png",
  path = "data/statsScripts/simmer/rapporten",
  width = 20,
  height = 18
)

# tibbles naar csv files ------------------

## events_wrangle tibble:
eventsWrangleFilename <- str_c(
  str_remove_all(as.character(Sys.Date()), "\\-"),
  "_events_wrangle.csv"
)

write_csv(
  x = events_wrangle |> mutate(run = run_date),
  file = str_c(here::here("output"), "/", eventsWrangleFilename),
  col_names = T
)

## tabel Benutting tibble:
tabelBenuttingFilename <- str_c(
  str_remove_all(as.character(Sys.Date()), "\\-"),
  "_tabel_benutting.csv"
)

write_csv(
  x = tabel_benutting |> mutate(run = run_date),
  file = str_c(here::here("output"), "/", tabelBenuttingFilename),
  col_names = T
)

## log_aankomst_ontslag tibble:
logAankomstOntslagFilename <- str_c(
  str_remove_all(as.character(Sys.Date()), "\\-"),
  "_log_aankomst_ontslag.csv"
)

write_csv(
  x = log_aankomst_ontslag |> mutate(run = run_date),
  file = str_c(here::here("output"), "/", logAankomstOntslagFilename),
  col_names = T
)
