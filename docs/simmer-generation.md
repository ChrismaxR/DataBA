# Simmer Synthetic Data Generation (Functional Overview)

**Scope**
- This documents the active simmer pipeline that generates synthetic hospital data.
- Entry points:
  - `data/generateScripts/simmer/simmerImplementatie.R` (simulation core)
  - `data/statsScripts/simmer/simmerStatistics.R` (wrangling + metrics + plots)
  - `data/generateScripts/simmer/simmerWriteToDisk.R` (persist outputs)

**Configuration (`data/generateScripts/simmer/simmerConfig.R`)**
- Simulation time: 5 days, each day = 24h; workday = 8h; `simDuration = simDays * dayMinutes`.
- Resources: 20 named hospital resources with fixed capacities.
- Arrivals: inter-arrival time is uniform between 1 and 5 minutes.
- Default service time functions exist but are overridden in the main implementation.
- Aandoening (condition) dimension table provides 33 condition labels.

**Simulation Core (`data/generateScripts/simmer/simmerImplementatie.R`)**
- Reproducibility: `set.seed(42)`.
- Resources:
  - `resource_definitie` is mapped to simmer resources.
  - Each resource has a daily work schedule: capacity during workday, 0 outside.
  - Queue size is infinite.
- Service time per resource:
  - `resource_durations` defines min/max per resource id.
  - `resource_timeout(resource_id)` returns a `runif(min,max)` duration.
- Workday spillover:
  - `service_step()` splits service into chunks that fit inside the remaining workday.
  - If service is unfinished at closing, the patient waits until next day, then resumes.
  - Uses `remaining_service` and `service_chunk` attributes and a rollback loop.

**Patient Routing**
- Each patient gets an `aandoeningId` (overridden to 1..33).
- All patients pass Reception (resource 1).
- The condition id maps to one of 19 routes (A–S).
- Each route is a 2-step sequence: diagnosis resource -> treatment resource.
- The mapping is defined in `aandoening_route` and resolved by `route_index()`.

**Arrivals and Run**
- Generator creates arrivals only during work hours each day.
- Arrival process repeats every day (`every = dayMinutes`) for `simDuration` minutes.
- Simulation is run in a single call: `run(until = simDuration)`.

**Logging and Monitoring**
- `log_()` writes to stdout; output is captured and parsed into `log_df`.
- Standard simmer monitors are collected:
  - `events` (arrivals per resource)
  - `attributes` (per arrival attributes)
  - `resources` (resource stats)

**Wrangling + Metrics (`data/statsScripts/simmer/simmerStatistics.R`)**
- Simulation time is anchored at `2025-01-01 09:00:00 UTC`.
- `events_wrangle` adds:
  - `waitTime`, resource factor levels, and real timestamps.
- `log_aankomst_ontslag` derives:
  - arrival/discharge times and total stay duration.
- Utilization per resource:
  - `sumActivityTime / (capacity * simDuration)`.
- Plots are built into a combined `rapport` object.

**Output to Disk (`data/generateScripts/simmer/simmerWriteToDisk.R`)**
- Saves `rapport` to `data/statsScripts/simmer/rapporten/` as:
  - `YYYYMMDD_simulatie_performance.png`
- Writes CSVs to `output/`:
  - `YYYYMMDD_events_wrangle.csv`
  - `YYYYMMDD_tabel_benutting.csv`
  - `YYYYMMDD_log_aankomst_ontslag.csv`

**Not in the active pipeline**
- `data/generateScripts/simmer/simmerChatGPT.R` is a discarded skeleton.
- `data/generateScripts/simmer/simmerTest.R` is a sandbox test of simmer basics.
