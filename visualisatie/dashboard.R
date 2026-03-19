# Dashboard voor Dr. Van Dalen - Theme Hospital Capaciteitsmanagement
# Draai vanuit de projectroot: shiny::runApp("visualisatie/dashboard.R")

library(shiny)
library(bslib)
library(tidyverse)
library(scales)
library(here)

# Laad meest recente output bestanden ----------------------------------------

find_latest_output <- function(pattern) {
  files <- list.files(here("output"), pattern = pattern, full.names = TRUE)
  if (length(files) == 0) stop("Geen output gevonden voor patroon: ", pattern)
  sort(files, decreasing = TRUE)[1]
}

events_wrangle <- read_csv(find_latest_output("events_wrangle"), show_col_types = FALSE) |>
  mutate(
    startTimeReal = ymd_hms(startTimeReal),
    endTimeReal   = ymd_hms(endTimeReal),
    simDag        = as.Date(startTimeReal)
  )

log_aankomst_ontslag <- read_csv(find_latest_output("log_aankomst_ontslag"), show_col_types = FALSE) |>
  mutate(
    aankomstTijdstipReal = ymd_hms(aankomstTijdstipReal),
    ontslagTijdstipReal  = ymd_hms(ontslagTijdstipReal),
    simDag               = as.Date(aankomstTijdstipReal),
    isOntslagen          = !is.na(ontslagTijdstip)
  )

tabel_benutting <- read_csv(find_latest_output("tabel_benutting"), show_col_types = FALSE)

# KPI-waarden ----------------------------------------------------------------

n_patienten   <- nrow(log_aankomst_ontslag)
n_wachtenden  <- sum(!log_aankomst_ontslag$isOntslagen)
n_ontslagen   <- sum(log_aankomst_ontslag$isOntslagen)
gem_wachttijd <- round(mean(events_wrangle$waitTime, na.rm = TRUE), 1)
gem_benutting <- mean(tabel_benutting$utilization, na.rm = TRUE)

# UI -------------------------------------------------------------------------

ui <- page_navbar(
  title    = "Theme Hospital \u2014 Capaciteitsdashboard",
  theme    = bs_theme(bootswatch = "flatly"),
  fillable = FALSE,

  # Tab 1: Overzicht ----
  nav_panel(
    "Overzicht",
    layout_columns(
      col_widths = c(4, 4, 4),
      value_box(
        title = "Nieuwe pati\u00ebnten",
        value = format(n_patienten, big.mark = "."),
        theme = "primary"
      ),
      value_box(
        title = "Nog in behandeling",
        value = format(n_wachtenden, big.mark = "."),
        theme = if (n_wachtenden > 100) "warning" else "success"
      ),
      value_box(
        title = "Gem. wachttijd (min)",
        value = gem_wachttijd,
        theme = if (gem_wachttijd > 30) "danger" else "success"
      )
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Pati\u00ebntentoeloop per simulatiedag"),
        plotOutput("plot_toeloop", height = "300px")
      ),
      card(
        card_header("Gem. wachttijd per kamertype (top 10)"),
        plotOutput("plot_top_wachttijd", height = "300px")
      )
    )
  ),

  # Tab 2: Wachtrijen ----
  nav_panel(
    "Wachtrijen",
    layout_columns(
      col_widths = c(6, 6),
      value_box(
        title = "Wachtenden",
        value = format(n_wachtenden, big.mark = "."),
        theme = "warning"
      ),
      value_box(
        title = "Gem. wachttijd (min)",
        value = gem_wachttijd,
        theme = if (gem_wachttijd > 30) "danger" else "primary"
      )
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Spreiding wachttijden per kamertype"),
        plotOutput("plot_wachttijd_boxplot", height = "400px")
      ),
      card(
        card_header("Gem. wachttijd per kamertype per dag"),
        plotOutput("plot_wachttijd_trend", height = "400px")
      )
    )
  ),

  # Tab 3: Capaciteit ----
  nav_panel(
    "Capaciteit",
    layout_columns(
      col_widths = c(4, 4, 4),
      value_box(
        title = "Kamertypen",
        value = nrow(tabel_benutting),
        theme = "primary"
      ),
      value_box(
        title = "Gem. benutting",
        value = scales::percent(gem_benutting, accuracy = 0.1),
        theme = if (gem_benutting > 0.8) "danger" else "success"
      ),
      value_box(
        title = "Ontslagen pati\u00ebnten",
        value = format(n_ontslagen, big.mark = "."),
        theme = "success"
      )
    ),
    card(
      card_header("Benutting per kamertype (% van beschikbare capaciteit in werkuren)"),
      plotOutput("plot_benutting", height = "480px")
    )
  ),

  # Tab 4: Ziekteverloop ----
  nav_panel(
    "Ziekteverloop",
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box(
        title = "Totaal pati\u00ebnten",
        value = format(n_patienten, big.mark = "."),
        theme = "primary"
      ),
      value_box(
        title = "Aandoeningen",
        value = n_distinct(log_aankomst_ontslag$aandoeningId),
        theme = "primary"
      ),
      value_box(
        title = "Ontslagen",
        value = format(n_ontslagen, big.mark = "."),
        theme = "success"
      ),
      value_box(
        title = "Nog aanwezig",
        value = format(n_wachtenden, big.mark = "."),
        theme = "warning"
      )
    ),
    layout_columns(
      col_widths = c(7, 5),
      card(
        card_header("Pati\u00ebnten per aandoening"),
        plotOutput("plot_aandoeningen", height = "480px")
      ),
      card(
        card_header("Verblijfsduur in ziekenhuis (minuten)"),
        plotOutput("plot_verblijfsduur", height = "480px")
      )
    )
  )
)

# Server ---------------------------------------------------------------------

server <- function(input, output, session) {

  ## Overzicht ----

  output$plot_toeloop <- renderPlot({
    log_aankomst_ontslag |>
      count(simDag) |>
      ggplot(aes(x = simDag, y = n)) +
      geom_col(fill = "#2c3e50") +
      geom_text(aes(label = n), vjust = -0.4, size = 3.5) +
      scale_x_date(date_labels = "%d %b") +
      labs(x = NULL, y = "Aantal pati\u00ebnten") +
      theme_minimal(base_size = 13)
  })

  output$plot_top_wachttijd <- renderPlot({
    events_wrangle |>
      group_by(resource) |>
      summarise(gemWachttijd = mean(waitTime, na.rm = TRUE), .groups = "drop") |>
      slice_max(gemWachttijd, n = 10) |>
      ggplot(aes(x = gemWachttijd, y = fct_reorder(resource, gemWachttijd))) +
      geom_col(fill = "#e74c3c") +
      geom_text(aes(label = round(gemWachttijd, 1)), hjust = -0.2, size = 3.5) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
      labs(x = "Gem. wachttijd (min)", y = NULL) +
      theme_minimal(base_size = 13)
  })

  ## Wachtrijen ----

  output$plot_wachttijd_boxplot <- renderPlot({
    events_wrangle |>
      ggplot(aes(
        y    = fct_reorder(resource, waitTime, .fun = median),
        x    = waitTime,
        fill = resource
      )) +
      geom_boxplot(show.legend = FALSE, outlier.alpha = 0.3) +
      labs(x = "Wachttijd (min)", y = NULL) +
      theme_minimal(base_size = 12)
  })

  output$plot_wachttijd_trend <- renderPlot({
    events_wrangle |>
      group_by(simDag, resource) |>
      summarise(gemWachttijd = mean(waitTime, na.rm = TRUE), .groups = "drop") |>
      ggplot(aes(
        x      = simDag,
        y      = gemWachttijd,
        colour = resource,
        group  = resource
      )) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_x_date(date_labels = "%d %b") +
      labs(x = NULL, y = "Gem. wachttijd (min)", colour = "Kamer") +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom")
  })

  ## Capaciteit ----

  output$plot_benutting <- renderPlot({
    tabel_benutting |>
      ggplot(aes(
        x    = utilization,
        y    = fct_reorder(resource, utilization),
        fill = utilization
      )) +
      geom_col() +
      geom_text(
        aes(label = scales::percent(utilization, accuracy = 0.1)),
        hjust = -0.1,
        size  = 3.5
      ) +
      scale_x_continuous(
        labels = scales::percent_format(),
        expand = expansion(mult = c(0, 0.15))
      ) +
      scale_fill_gradient(low = "#27ae60", high = "#e74c3c", guide = "none") +
      labs(x = "Benutting", y = NULL) +
      theme_minimal(base_size = 13)
  })

  ## Ziekteverloop ----

  output$plot_aandoeningen <- renderPlot({
    log_aankomst_ontslag |>
      count(aandoeningOmschrijving, isOntslagen) |>
      ggplot(aes(
        y    = fct_reorder(aandoeningOmschrijving, n, sum),
        x    = n,
        fill = isOntslagen
      )) +
      geom_col() +
      scale_fill_manual(
        values = c("TRUE" = "#27ae60", "FALSE" = "#e67e22"),
        labels = c("TRUE" = "Ontslagen", "FALSE" = "Nog aanwezig")
      ) +
      labs(x = "Aantal pati\u00ebnten", y = NULL, fill = NULL) +
      theme_minimal(base_size = 12) +
      theme(legend.position = "top")
  })

  output$plot_verblijfsduur <- renderPlot({
    log_aankomst_ontslag |>
      filter(!is.na(duratieInZiekenhuis)) |>
      ggplot(aes(x = duratieInZiekenhuis)) +
      geom_histogram(bins = 30, fill = "#2980b9", colour = "white") +
      labs(x = "Verblijfsduur (min)", y = "Aantal pati\u00ebnten") +
      theme_minimal(base_size = 12)
  })
}

shinyApp(ui, server)
