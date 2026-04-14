# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

---

## Scope Rules — read before touching anything

- **Edit one script per task** unless explicitly instructed otherwise.
- Ask before creating any new file. Confirm filename and destination path first.
- `output/` contains generated artifacts — never edit CSVs there directly.
- `data/generateScripts/simmer/simmerConfig.R` is the single source of truth for resources, trajectories, and conditions. Do not duplicate or re-derive these in other scripts.
- `docs/AGENTS.md` owns the resource/trajectory/condition mapping tables — do not restate them elsewhere.
- `dashboard/sources/hospital/` SQL files are read-only unless the task is explicitly about a query.
- Never touch `simmerChatGPT.R` or `simmerTest.R` — these are discarded skeletons.

---

## Project Overview

Theme Hospital waiting times & capacity analytics dashboard. End-to-end pipeline:

```
Discrete-event simulation (R/simmer)
  → per-run CSV output (output/YYYYMMDD_*.csv)
    → monthly aggregation (R/dplyr)
      → aggregated CSVs (output/aggregated/YYYY_MM_*.csv)
        → Evidence.dev dashboard (DuckDB queries)
```

Dashboard content is in Dutch.

---

## Architecture

The pipeline runs in this strict order. Each step has one entry script.

### 1. Config
**`data/generateScripts/simmer/simmerConfig.R`**

- 20 resources with capacities
- 33 conditions (`aandoeningId` 1–33)
- 19 treatment trajectories (A–S)
- Simulation duration: 365 days (`simDays <- 365`), seed = 42
- Quarterly arrival rate schedule (`aankomst_schema`)
- Seasonal service time multiplier schedule (`service_schema`)
- Epidemic bell-curve parameters (`epidemie_*`)

### 2. Simulation
**`data/generateScripts/simmer/simmerImplementatie.R`**

Discrete-event simulation using the `simmer` R package. Produces three in-memory objects used downstream:
- `events_wrangle` — one row per patient × resource, with `waitTime`, `activityTime`, `startTimeReal`
- `log_aankomst_ontslag` — one row per patient, with arrival/discharge timestamps and total stay
- `tabel_benutting` — utilisation rate per resource

### 3. Statistics & plots
**`data/statsScripts/simmer/simmerStatistics.R`**

Sources simmerConfig.R and simmerImplementatie.R. Computes summary statistics and builds the `rapport` plot object.

### 4. Output to disk
**`data/generateScripts/simmer/simmerWriteToDisk.R`**

Writes to `output/`:
- `YYYYMMDD_events_wrangle.csv`
- `YYYYMMDD_tabel_benutting.csv`
- `YYYYMMDD_log_aankomst_ontslag.csv`

Also saves `rapport` PNG to `data/statsScripts/simmer/rapporten/`.

### 5. Monthly aggregation ← new layer
**`data/aggregateScripts/monthlyAggregate.R`** *(to be created)*

Reads all dated CSVs from `output/` using `list.files()` + `purrr::map_dfr()`. Aggregates to monthly grain with dplyr. Writes to `output/aggregated/`:
- `maandelijks_wachttijd.csv`
- `maandelijks_benutting.csv`
- `maandelijks_instroom.csv`

See **Data Contract** section for expected column schemas.

### 6. Dashboard
**`dashboard/`** (Evidence.dev / Svelte + DuckDB)

Reads **aggregated CSVs only** via `read_csv_auto()`. Do not wire dashboard queries to raw `events_wrangle` or `log_aankomst_ontslag` — those are too large and unfit for direct BI consumption.

Four pages: `index.md` (KPI overview), `capaciteit.md` (utilisation), `wachtrijen.md` (queues), `ziekteverloop.md` (patient journey).

---

## Data Contract

These are the required schemas for the monthly aggregation output. Column names are in snake_case Dutch. The dashboard SQL must match exactly.

### `maandelijks_wachttijd.csv`
| column | type | description |
|---|---|---|
| resource_id | integer | 1–20 |
| resource_naam | character | from simmerConfig |
| jaar | integer | e.g. 2025 |
| maand | integer | 1–12 |
| gem_wachttijd | double | mean wait time in minutes |
| p95_wachttijd | double | 95th percentile wait |
| n_patienten | integer | visits to this resource that month |

### `maandelijks_benutting.csv`
| column | type | description |
|---|---|---|
| resource_id | integer | 1–20 |
| resource_naam | character | |
| jaar | integer | |
| maand | integer | |
| bezettingsgraad | double | 0–1, sumActivityTime / (capacity × maand_minuten) |

### `maandelijks_instroom.csv`
| column | type | description |
|---|---|---|
| aandoening_id | integer | 1–33 |
| aandoening | character | from simmerConfig |
| jaar | integer | |
| maand | integer | |
| n_patienten | integer | unique arrivals that month |

---

## Simmer API — correct patterns

Claude frequently hallucinates simmer function signatures. Use these anchors.

```r
# Assigning a random attribute at arrival time (function form required — not a value)
set_attribute("aandoeningId", function() sample(1L:33L, 1))

# Reading an attribute inside a trajectory step
get_attribute(env, "aandoeningId")

# Branching on an attribute (option index is 1-based; number of branches must match)
branch(
  function() get_attribute(env, "aandoeningId"),
  continue = rep(TRUE, 33),
  traj_A, traj_A, traj_A,   # aandoeningId 1, 2, 3 → trajectory A
  ...
)

# Daily workday capacity schedule (period = one day in minutes)
schedule(c(0, workDayStart, workDayEnd), c(0, capacity, 0), period = dayMinutes)

# Rollback loops: n counts steps backward in the trajectory, not lines
rollback(n = 2, times = Inf)

# set_capacity at runtime (not used in generation — only for scenario testing)
set_capacity("Reception", value = 5)
```

When in doubt about a simmer function, check `?simmer::trajectory` before writing code. Do not infer signatures from memory.

---

## R / dplyr Conventions

- Use **dplyr + tidyr** for all data wrangling in `statsScripts/` and `aggregateScripts/`.
- No base-R `for` loops for data transformation — use `group_by() |> summarise()` or `purrr::map()`.
- Reading multiple dated CSVs: `list.files("output/", pattern = ".*_events_wrangle\\.csv", full.names = TRUE) |> purrr::map_dfr(read_csv)`.
- Column names: snake_case Dutch (`gem_wachttijd`, `bezettingsgraad`, `aankomst_tijdstip`).
- Prefer `|>` (base pipe) over `%>%` in new code.
- Functions should be small and named by intent. Add a one-line comment for non-obvious logic.
- Consistently use tidyverse within a file — do not mix base-R and dplyr styles.

---

## Dashboards

This project uses **Evidence.dev** (not Shiny, Streamlit, or any other framework). Evidence.dev uses Markdown files with embedded SQL blocks, compiled to a static site with DuckDB.

Do not suggest alternative dashboard frameworks unless explicitly asked.

---

## Commands

```bash
# Dashboard development
cd dashboard
npm run dev        # Start dev server with auto-refresh
npm run build      # Production build
npm run preview    # Preview production build
npm run sources    # Validate data sources
```

```bash
# R pipeline (run in order)
Rscript data/generateScripts/simmer/simmerImplementatie.R
Rscript data/statsScripts/simmer/simmerStatistics.R
Rscript data/generateScripts/simmer/simmerWriteToDisk.R
Rscript data/aggregateScripts/monthlyAggregate.R   # once created
```

R scripts can also be run interactively in RStudio.

---

## Key Conventions

- Always `set.seed(42)` in entry scripts. Document any additional seeds inline.
- Do **not** commit generated CSVs in `output/` — they are large and reproducible.
- Keep `data/statsScripts/` and `data/generateScripts/` in sync when changing data shapes.
- Work on the `simmerImplementation` branch, not `main`.
- Output filenames follow the pattern `YYYYMMDD_<name>.csv` — do not alter this convention.
- Validate simmer function calls against the API before writing. See **Simmer API** section above.

---

## Reference

Full resource / trajectory / condition mapping tables: **`docs/AGENTS.md`**

Functional overview of the active simulation pipeline: **`docs/simmer-generation.md`**
