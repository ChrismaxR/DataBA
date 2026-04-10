---
title: Capaciteit
---

```sql benutting
SELECT *
FROM hospital.benutting
```

```sql maxbenutting
SELECT 
    max(utilization) as max, 
    avg(utilization) as avg
FROM hospital.benutting
```


<Grid cols=2>
  <BigValue
    data={maxbenutting}
    value=avg
    title="Gem. benutting (%)"
    fmt=pct
  />
  <BigValue
    data={maxbenutting}
    value=max
    title="Hoogste benutting (%)"
    fmt=pct
  />
</Grid>

<BarChart
  data={benutting}
  x=resource
  y=utilization
  swapXY=true
  title="Benutting per kamertype (% van beschikbare capaciteit in werkuren)"
  xAxisTitle="Benutting (%)"
  yAxisTitle="% Benutting"
  yFmt=pct
  colorPalette={['#27ae60', '#f39c12', '#e74c3c']}
/>

<DataTable data={benutting} title="Benutting" />
