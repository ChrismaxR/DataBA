---
title: Capaciteit
---

```sql kpi_capaciteit
SELECT
  COUNT(*)                            AS n_kamertypen,
  ROUND(AVG(utilization) * 100, 1)   AS gem_benutting_pct,
  ROUND(MAX(utilization) * 100, 1)   AS max_benutting_pct
FROM hospital.benutting
```

```sql benutting_per_kamer
SELECT
  resource,
  capacity,
  ROUND(sumActivityTime, 0)           AS sumActivityTime,
  ROUND(utilization * 100, 1)         AS benutting_pct
FROM hospital.benutting
ORDER BY utilization DESC
```

<Grid cols=3>
  <BigValue
    data={kpi_capaciteit}
    value=n_kamertypen
    title="Kamertypen"
  />
  <BigValue
    data={kpi_capaciteit}
    value=gem_benutting_pct
    title="Gem. benutting (%)"
    fmt=num1
  />
  <BigValue
    data={kpi_capaciteit}
    value=max_benutting_pct
    title="Hoogste benutting (%)"
    fmt=num1
  />
</Grid>

<BarChart
  data={benutting_per_kamer}
  x=resource
  y=benutting_pct
  swapXY=true
  title="Benutting per kamertype (% van beschikbare capaciteit in werkuren)"
  xAxisTitle="Benutting (%)"
  yAxisTitle=null
  colorPalette={['#27ae60', '#f39c12', '#e74c3c']}
/>

<DataTable data={benutting_per_kamer} title="Benutting per kamertype" />
