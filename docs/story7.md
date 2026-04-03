# Voorgestelde opzet van een evidence dashboard
Claude cowork gevraagd om op basis van voorgaande 6 stories een ontwerp voor een dashboard te genereren. 
Hieronder de respons: 


**Start with the persona's actual question**

Dr. Van Dalen's central question is: *"Where do I need to add or redistribute capacity next month to keep waiting times below X?"* That question is fundamentally about the **relationship between capacity and queue**, not about either in isolation. Story 3's tab structure treats them as four separate topics (Main / Queue / Capacity / Disease Flow), which is clean but misses the core analytical narrative. A stronger structure would reflect the causal chain:

> **Demand** (how many patients, with which conditions) → **Capacity** (which rooms are available and for how long) → **Queue** (the outcome)

That chain is the story the dashboard should tell, and ideally the Main tab should give Dr. Van Dalen a quick answer to whether that chain is in balance or not.

---

**Tab structure I'd propose**

**Tab 1 – Operational Health (the executive summary)**
Big numbers for the current month: total patients, average wait time overall, and a capacity utilisation rate. The crucial addition Story 3 marks as "nice to have" — comparison to last month — should be standard here. A COO reviewing monthly performance needs trend direction at a glance, not just a snapshot. I'd also argue this tab should include a single "tension chart": a dual-axis or combined view showing patient volume alongside average wait times over the past 12 months. That single chart answers the diagnostic question — are waits rising *because* volume increased, or despite stable volume (suggesting a capacity problem)?

**Tab 2 – Queue Length**
This is the KPI Dr. Van Dalen is ultimately accountable for, so it earns its own tab. The most actionable chart here is wait time per specialisme ranked from worst to best — a horizontal bar chart works well for this. The key design decision is adding a **threshold line** representing the target ("below X"). Without that reference, the chart shows you what is, not whether it's acceptable. Over time, a line chart per specialisme for the past year allows her to distinguish persistent problems from one-off spikes.

**Tab 3 – Capacity**
Rooms available, rooms out of order, staff breaks/vacancies — but the number that matters most is **utilisation rate per kamerType**. Story 4's pseudo-code already operationalises this (metric 12/13). A stacked view of room status over time (in use / machine down / staff on break / vacant) by kamerType gives Dr. Van Dalen visibility into *why* a kamerType is underperforming. This is the lever tab — the charts here should point directly to actions she can take.

**Tab 4 – Disease & Patient Flow**
Volume trends, diagnoses per specialisme, undiagnosed vs. diagnosed patients. This is the demand-side context. It's the least immediately actionable tab for her primary question, but it matters for her longer-term instruments — spotting changing disease patterns, planning HR strategy. It earns its place, but as the last tab rather than being buried or elevated.

---

**Key design choices worth making explicit**

The **time grain** matters a lot here. Dr. Van Dalen reviews monthly, so monthly aggregates are the primary lens — but she'll want to drill into daily data when something looks wrong. Building in a date filter or a click-through from monthly to daily is more useful than trying to show both at once.

**Specialisme-level breakdown** should be available everywhere, not just in the Queue tab. Capacity utilisation by kamerType and patient flow by aandoening are what make the dashboard actionable rather than just descriptive. The global headline numbers tell you there's a problem; the breakdowns tell you where to act.

The **forecasting requirement** from Story 2 was quietly dropped in Story 3. I'd surface that as a deliberate design choice rather than an omission — even a simple "if current trends continue" projection on the queue chart would give Dr. Van Dalen a forward-looking signal, which is ultimately what her question is asking for.

Finally, **Story 3's tab numbering error** (Tab 1 → Tab 4 → Tab 3 → Tab 4) suggests this was drafted quickly without a final pass. In a portfolio context it's worth resolving, because the tab order signals whether the designer thought through the narrative flow deliberately. The logical order — Overview → Queue → Capacity → Disease Flow — moves from output back to inputs, which mirrors how a COO would diagnose a problem: "waits are up → utilisation is high → demand has increased in these specialismes."