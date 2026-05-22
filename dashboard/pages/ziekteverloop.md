---
title: Ziekteverloop
---

```sql kpi_ziekte
SELECT
  COUNT(*)                                          AS n_patienten,
  COUNT(DISTINCT aandoeningId)                      AS n_aandoeningen,
  SUM(CASE WHEN isOntslagen THEN 1 ELSE 0 END)      AS n_ontslagen,
  SUM(CASE WHEN NOT isOntslagen THEN 1 ELSE 0 END)  AS n_wachtenden
FROM hospital.patienten
```

```sql aandoeningen
SELECT
  aandoeningOmschrijving,
  SUM(CASE WHEN isOntslagen THEN 1 ELSE 0 END)     AS ontslagen,
  SUM(CASE WHEN NOT isOntslagen THEN 1 ELSE 0 END) AS nog_aanwezig,
  COUNT(*)                                          AS totaal
FROM hospital.patienten
GROUP BY aandoeningOmschrijving
ORDER BY totaal DESC
```

```sql verblijfsduur
SELECT
  aandoeningOmschrijving,
  ROUND(AVG(duratieInZiekenhuis), 0)    AS gem_verblijfsduur,
  ROUND(MEDIAN(duratieInZiekenhuis), 0) AS mediaan_verblijfsduur,
  ROUND(MAX(duratieInZiekenhuis), 0)    AS max_verblijfsduur
FROM hospital.patienten
WHERE duratieInZiekenhuis IS NOT NULL
GROUP BY aandoeningOmschrijving
ORDER BY gem_verblijfsduur DESC
```

```sql toeloop_per_dag
SELECT
  simDag,
  SUM(CASE WHEN isOntslagen THEN 1 ELSE 0 END)     AS ontslagen,
  SUM(CASE WHEN NOT isOntslagen THEN 1 ELSE 0 END) AS nog_aanwezig
FROM hospital.patienten
GROUP BY simDag
ORDER BY simDag
```

<Grid cols=4>
  <BigValue data={kpi_ziekte} value=n_patienten    title="Totaal patiënten" />
  <BigValue data={kpi_ziekte} value=n_aandoeningen title="Aandoeningen" />
  <BigValue data={kpi_ziekte} value=n_ontslagen    title="Ontslagen" />
  <BigValue data={kpi_ziekte} value=n_wachtenden   title="Nog aanwezig" />
</Grid>

<AreaChart
  data={toeloop_per_dag}
  x=simDag
  y={['ontslagen', 'nog_aanwezig']}
  type=stacked
  title="Dagverloop: ontslagen vs. nog aanwezig"
  xAxisTitle="Dag"
  yAxisTitle="Aantal patiënten"
/>



<Grid cols=2>
  <BarChart
    data={verblijfsduur}
    x=aandoeningOmschrijving
    y=gem_verblijfsduur
    swapXY=true
    title="Gem. verblijfsduur per aandoening (min)"
    xAxisTitle="Minuten"
    yAxisTitle=null
  />

  <BarChart
    data={aandoeningen}
    x=aandoeningOmschrijving
    y={['ontslagen', 'nog_aanwezig']}
    swapXY=true
    type=stacked
    title="Patiënten per aandoening"
    xAxisTitle="Aantal patiënten"
    yAxisTitle=null
  />

</Grid>
