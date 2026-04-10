# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Theme Hospital waiting times & capacity analytics dashboard. End-to-end pipeline: discrete-event simulation in R → CSV output → DuckDB queries → Evidence.dev BI dashboard.

## Commands

```bash
# Dashboard development
cd dashboard
npm run dev        # Start dev server with auto-refresh
npm run build      # Production build
npm run preview    # Preview production build
npm run sources    # Validate data sources
```

R scripts are run interactively in RStudio or via `Rscript`:
```bash
Rscript data/generateScripts/simmer/simmerImplementatie.R
Rscript data/statsScripts/simmer/simmerStatistics.R
```

## Architecture

The pipeline is strictly ordered:

1. **Config** → `data/generateScripts/simmer/simmerConfig.R`
   Defines 20 hospital rooms with capacities, 33 conditions, 19 treatment trajectories (A–S), arrival intervals, and simulation duration (62 days, seed=42).

2. **Generation** → `data/generateScripts/simmer/simmerImplementatie.R`
   Discrete-event simulation using the `simmer` R package. Uses `set_attribute` to assign `aandoeningId` per patient and routes them through trajectories. **Needs expansion** — the current implementation is minimal.

3. **Statistics** → `data/statsScripts/simmer/simmerStatistics.R`
   Computes wait times, occupancy rates, and timestamps from raw simulation events.

4. **Output** → `data/generateScripts/simmer/simmerWriteToDisk.R`
   Writes CSVs to `output/`: `events_wrangle.csv`, `log_aankomst_ontslag.csv`, `tabel_benutting.csv`.

5. **Dashboard** → `dashboard/` (Evidence.dev / Svelte)
   DuckDB queries in `dashboard/sources/` read output CSVs via `read_csv_auto()`. Four pages: index (overview KPIs), capaciteit (utilization), wachtrijen (queues), ziekteverloop (patient journey).

Shared utilities are in `data/utils.R`.

## Key Conventions

- Always `set.seed(42)` in entry scripts; document any additional seeds.
- Do **not** commit generated CSV output — they are large and reproducible.
- Keep `data/statsScripts/` and `data/generateScripts/` in sync.
- Work on the `simmerImplementation` branch, not `main`.
- Functions should be small and named by intent; prefer tidyverse consistently within a file.
- Trajectories all start at Resource 1 (Reception, capacity 4) via a shared `traj0` before branching by `aandoeningId`. See `docs/AGENTS.md` for the full resource/trajectory/condition mapping tables.
