# AGENTS.md

## Purpose
This repo contains R scripts to generate synthetic data with `simmer` and compute statistics. Keep runs reproducible and avoid committing large generated artifacts.

## Working conventions
- Prefer small, incremental changes and keep `data/statsScripts/` and `data/generateScripts/` in sync.
- Keep random processes reproducible: set and document seeds in entry scripts.
- Avoid committing generated datasets unless explicitly requested.

## Common entry points
- Stats: `data/statsScripts/simmer/simmerStatistics.R`
- Generation: `data/generateScripts/simmer/simmerImplementatie.R`
- Config: `data/generateScripts/simmer/simmerConfig.R`
- Utilities: `data/utils.R`

## Run guidance
- Use this file to expand on the existing generation script: `data/generateScripts/simmer/simmerImplementatie.R`
- this script contains a minimal envisaged implementation, but needs expansion and extrapalotion. 
- Confirm expected output paths before long runs.
- If adding new outputs, document the filenames/paths here.

## Code style
- Keep functions small and named by intent.
- Prefer tidyverse consistently within a file.
- Add short comments for non‑obvious logic.

## Branching
- Work on the `simmerImplementation` branch, not on main.

## Add resources to the simmer env
necessary resources and their capacity (some already exist)
| id | resourceName              | capacity |
|----|---------------------------|----------|
|  1 | Reception                 |      4   |
|  2 | GP’s Office               |      4   |
|  3 | General Diagnosis Room    |      3   |
|  4 | Cardiogram                |      1   |
|  5 | Scanner                   |      2   |
|  6 | Ultrascan                 |      2   |
|  7 | X-Ray                     |      3   |
|  8 | The Ward                  |      3   |
|  9 | Psychiatric Room          |      2   |
| 10 | Pharmacy                  |      3   |
| 11 | Operating Theatre         |      2   |
| 12 | Inflation Room            |      1   |
| 13 | DNA Fixer                 |      1   |
| 14 | Hair Restoration          |      1   |
| 15 | ResearchDept              |      0   |
| 16 | Slack Tongue Clinic       |      1   |
| 17 | Fracture Clinic           |      1   |
| 18 | Electrolysis              |      1   |
| 19 | Jelly Vat                 |      1   |
| 20 | Decontamination           |      1   |

## Add trajectories
Link between a trajectory and which resources must be used. The `aandoeningId` is the 
differentiating factor: this is further defined in the following section. These Id' must be generated with the set_attribute function. 
| trajectoryName | firstResource |  secondResource | thirdResource | aandoeningId |
|----------------|---------------|-----------------|---------------|--------------|
| A              |  1, but defined in traj0 |     2           |        8      |           1  |
| A              |  1, but defined in traj0 |     2           |        8      |           2  |
| A              |  1, but defined in traj0 |     2           |        8      |           3  |
| B              |  1, but defined in traj0 |     2           |       10      |           4  |
| B              |  1, but defined in traj0 |     2           |       10      |           5  |
| B              |  1, but defined in traj0 |     2           |       10      |           6  |
| B              |  1, but defined in traj0 |     2           |       10      |           7  |
| C              |  1, but defined in traj0 |     2           |       18      |           8  |
| C              |  1, but defined in traj0 |     2           |       18      |           9  |
| D              |  1, but defined in traj0 |     2           |       14      |          10  |
| E              |  1, but defined in traj0 |     2           |        9      |          11  |
| E              |  1, but defined in traj0 |     2           |        9      |          12  |
| E              |  1, but defined in traj0 |     2           |        9      |          13  |
| F              |  1, but defined in traj0 |     3           |       11      |          14  |
| F              |  1, but defined in traj0 |     3           |       11      |          15  |
| F              |  1, but defined in traj0 |     3           |       11      |          16  |
| F              |  1, but defined in traj0 |     3           |       11      |          17  |
| G              |  1, but defined in traj0 |     3           |       10      |          18  |
| G              |  1, but defined in traj0 |     3           |       10      |          19  |
| H              |  1, but defined in traj0 |     3           |       18      |          20  |
| I              |  1, but defined in traj0 |     3           |       12      |          21  |
| J              |  1, but defined in traj0 |     3           |       16      |          22  |
| K              |  1, but defined in traj0 |     4           |       17      |          23  |
| L              |  1, but defined in traj0 |     7           |       17      |          24  |
| L              |  1, but defined in traj0 |     7           |       17      |          25  |
| L              |  1, but defined in traj0 |     7           |       17      |          26  |
| M              |  1, but defined in traj0 |     7           |       11      |          27  |
| N              |  1, but defined in traj0 |     7           |       10      |          28  |
| O              |  1, but defined in traj0 |     7           |       20      |          29  |
| P              |  1, but defined in traj0 |     5           |       19      |          30  |
| Q              |  1, but defined in traj0 |     5           |       10      |          31  |
| R              |  1, but defined in traj0 |     6           |       10      |          32  |
| S              |  1, but defined in traj0 |     6           |       13      |          33  |

### Definition of `aandoeningId`

| id | aandoening |
|----|------------------|
|  1 | Sleeping Illness |
|  2 | Discrete Itching |
|  3 | Fake Blood |
|  4 | The Squits |
|  5 | Sweaty Palms |
|  6 | Gastric Ejections |
|  7 | Uncommon Cold |
|  8 | Chronic Nosehair |
|  9 | Hairyitis |
| 10 | Baldness |
| 11 | King Complex |
| 12 | Infectious Laughter |
| 13 | TV Personalities |
| 14 | Ruptured Nodules |
| 15 | Broken Wind |
| 16 | Golf Stones |
| 17 | Iron Lungs |
| 18 | Gut Rot |
| 19 | Heaped Piles |
| 20 | 3rd Degree Sideburns |
| 21 | Bloaty Head |
| 22 | Slack Tongue |
| 23 | Broken Heart |
| 24 | Spare Ribs |
| 25 | Corrugated Ankles |
| 26 | Fractured Bones |
| 27 | Kidney Beans |
| 28 | Unexpected Swelling |
| 29 | Serious Radiation |
| 30 | Jellyitis |
| 31 | Transparency |
| 32 | Invisibility |
| 33 | Alien DNA |
