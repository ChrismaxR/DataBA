source("src/generateScripts/simmerConfig.R")

dim_aandoeningRoutes <- readr::read_csv(
  "dashboard/sources/hospital/AandoeningRoutes.csv"
) |>
  dplyr::left_join(
    resource_definitie |>
      dplyr::transmute(
        id,
        diagnoseCapacity = capacity
      ),
    by = c("diagnoseId" = "id")
  ) |>
  dplyr::left_join(
    resource_definitie |>
      dplyr::transmute(
        id,
        behandelingType = resource_type,
        behandelingCapacity = capacity
      ),
    by = c("behandelingId" = "id")
  )


collapsibleTree::collapsibleTree(
  df = dim_aandoeningRoutes,
  root = "Receptie",
  c("diagnose", "behandeling", "aandoeningNaam"),
  collapsed = F,
  height = 750
)
