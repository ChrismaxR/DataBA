---
title: Theme Hospital — Overzicht
---

```sql kpi
SELECT
  COUNT(DISTINCT patient)                           AS n_patienten,
  SUM(CASE WHEN NOT isOntslagen THEN 1 ELSE 0 END)  AS n_wachtenden,
  ROUND(AVG(waitTime), 1)                           AS gem_wachttijd
FROM hospital.patienten p
LEFT JOIN hospital.events e USING (patient)
```

```sql toeloop_per_dag
SELECT
  simDag,
  COUNT(*) AS n_patienten
FROM hospital.patienten
GROUP BY simDag
ORDER BY simDag
```

```sql top_wachttijd
SELECT
  resource,
  ROUND(AVG(waitTime), 1) AS gem_wachttijd
FROM hospital.events
GROUP BY resource
ORDER BY gem_wachttijd DESC
LIMIT 10
```

<Grid cols=3>
  <BigValue
    data={kpi}
    value=n_patienten
    title="Nieuwe patiënten"
  />
  <BigValue
    data={kpi}
    value=n_wachtenden
    title="Nog in behandeling"
  />
  <BigValue
    data={kpi}
    value=gem_wachttijd
    title="Gem. wachttijd (min)"
  />
</Grid>

<Grid cols=2>
  <BarChart
    data={toeloop_per_dag}
    x=simDag
    y=n_patienten
    title="Patiëntentoeloop per simulatiedag"
    xAxisTitle="Dag"
    yAxisTitle="Aantal patiënten"
  />

  <BarChart
    data={top_wachttijd}
    x=resource
    y=gem_wachttijd
    swapXY=true
    title="Gem. wachttijd per kamertype (top 10)"
    xAxisTitle="Gem. wachttijd (min)"
    yAxisTitle=null
  />
</Grid>
