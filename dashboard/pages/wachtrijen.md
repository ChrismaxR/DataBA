---
title: Wachtrijen
---

```sql kpi_wachtrijen
SELECT
  SUM(CASE WHEN NOT isOntslagen THEN 1 ELSE 0 END) AS n_wachtenden,
  ROUND(AVG(e.waitTime), 1)                         AS gem_wachttijd
FROM hospital.patienten p
LEFT JOIN hospital.events e ON p.patient = e.name
```

```sql wachttijd_per_kamer
SELECT
  resource,
  ROUND(AVG(waitTime), 1)    AS gem_wachttijd,
  ROUND(MEDIAN(waitTime), 1) AS mediaan_wachttijd,
  ROUND(MAX(waitTime), 1)    AS max_wachttijd
FROM hospital.events
GROUP BY resource
ORDER BY gem_wachttijd DESC
```

```sql wachttijd_trend
SELECT
  simDag,
  resource,
  ROUND(AVG(waitTime), 1) AS gem_wachttijd
FROM hospital.events
GROUP BY simDag, resource
ORDER BY simDag, resource
```

<Grid cols=2>
  <BigValue
    data={kpi_wachtrijen}
    value=n_wachtenden
    title="Wachtenden"
  />
  <BigValue
    data={kpi_wachtrijen}
    value=gem_wachttijd
    title="Gem. wachttijd (min)"
  />
</Grid>

<BarChart
  data={wachttijd_per_kamer}
  x=resource
  y=gem_wachttijd
  swapXY=true
  title="Gem. wachttijd per kamertype"
  xAxisTitle="Gem. wachttijd (min)"
  yAxisTitle=null
/>

<LineChart
  data={wachttijd_trend}
  x=simDag
  y=gem_wachttijd
  series=resource
  title="Ontwikkeling gem. wachttijd per kamertype per dag"
  xAxisTitle="Dag"
  yAxisTitle="Gem. wachttijd (min)"
/>

<DataTable data={wachttijd_per_kamer} title="Wachttijden per kamertype" />
