
⸻

1. Repository structure (signals competence immediately)

/README.md              # narrative, not docs
/docs/
  ├─ problem.md         # framing & public value
  ├─ data_sources.md    # why this data, limitations
  ├─ architecture.md    # simple, explicit choices
/data/
  ├─ raw/               # immutable
  ├─ processed/         # curated
  └─ README.md
/etl/
  ├─ ingest.R           # or python
  ├─ transform.R
  └─ validate.R
/warehouse/
  └─ schema.sql
/bi/
  ├─ dashboard.pbix     # or link if cloud
  └─ metrics.md

This already communicates:
	•	analytical framing
	•	pipeline thinking
	•	separation of concerns
	•	pragmatism

⸻

2. Project: fields (extended but still minimal)

Required fields
	•	Type: Epic | Story | Task
	•	Status: Idea | Backlog | Ready | In progress | Blocked | Done

Analyst-signal fields (important)
	•	Phase (Single select)
Problem framing
Data sourcing
Ingestion
Wrangling & modelling
Validation
Visualisation
Narrative & insights
	•	Deliverable (Single select)
Decision question
Dataset
Data model
Metric definition
Dashboard
Insight
	•	Skill signal (Multi select)
Stakeholder framing
Data quality
SQL modelling
R / Python wrangling
Data engineering basics
Data storytelling
BI design

This makes the project readable as a portfolio.

⸻

3. Epics (this is the backbone)

Create exactly 5 epics:

Epic 1 — Problem & Public Value
	•	Phase: Problem framing
	•	Deliverable: Decision question
	•	Outcome: What decision does this dashboard enable?

Epic 2 — Data Sourcing & Assessment
	•	Phase: Data sourcing
	•	Deliverable: Dataset
	•	Outcome: Why this data is “good enough”

Epic 3 — Ingestion & Storage
	•	Phase: Ingestion
	•	Deliverable: Data model
	•	Outcome: Reproducible, explainable pipeline

Epic 4 — Transformation & Metrics
	•	Phase: Wrangling & modelling
	•	Deliverable: Metric definition
	•	Outcome: Trustworthy numbers

Epic 5 — BI & Narrative
	•	Phase: Visualisation
	•	Deliverable: Dashboard
	•	Outcome: Insight, not charts

⸻

4. Stories per epic (example level of detail)

Epic 1 — Stories
	•	Define decision question
	•	Identify target user
	•	Define success criteria for dashboard

Skill signal: analyst framing, not tech

⸻

Epic 2 — Stories
	•	Identify open datasets
	•	Assess data completeness & bias
	•	Document limitations

Skill signal: realism, data literacy

⸻

Epic 3 — Stories
	•	Design ingestion approach (batch, manual, API)
	•	Implement raw → processed flow
	•	Define storage schema

Skill signal: data engineering lite, not cosplay

⸻

Epic 4 — Stories
	•	Define grain of fact table
	•	Define metrics & edge cases
	•	Validate numbers vs source

Skill signal: analytics engineering thinking

⸻

Epic 5 — Stories
	•	Sketch dashboard wireframe
	•	Build dashboard
	•	Write insight narrative

Skill signal: data communication

⸻

5. Tasks (what you actually move on the board)

Tasks should be boringly concrete:
	•	“Profile missing values in raw dataset”
	•	“Define metric: X (formula + caveats)”
	•	“Validate totals vs source CSV”
	•	“Refactor transformation for readability”

Avoid:
	•	“Do ETL”
	•	“Build dashboard”

Reviewers hate vagueness.

⸻

6. Project views (portfolio-friendly)

View 1 — Journey (Table)
	•	Group by: Phase
	•	Sort by: Epic → Story → Task
This tells a clean end-to-end story.

View 2 — Execution (Board)
	•	Columns: Status
	•	Filter: Type != Epic

View 3 — Skill coverage (Table)
	•	Group by: Skill signal
	•	Filter: Status = Done

This explicitly shows breadth without claiming it.

⸻

7. README.md (this matters more than the code)

Structure it like this:
	1.	The decision problem
	2.	Why this data
	3.	Architecture (1 diagram, simple)
	4.	Key metrics & assumptions
	5.	Dashboard screenshots
	6.	What I would improve with more time

That last point screams seniority.

⸻

8. What this setup communicates about you
	•	You think in decisions, not datasets
	•	You understand data lifecycle, not just charts
	•	You respect constraints
	•	You can bridge business ↔ data ↔ BI

This aligns perfectly with:
	•	Business Analyst
	•	Analytics Engineer (junior–mid)
	•	Data Communication / BI roles

