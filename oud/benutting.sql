-- Maandelijkse benutting per resource, berekend met correcte maanddenominant
-- (capacity × werkdagminuten × kalenderdagen in die maand)
SELECT
  resource_id,
  resource_naam   AS resource,
  jaar,
  maand,
  bezettingsgraad AS utilization,
  n_patienten
FROM read_csv_auto('../output/aggregated/maandelijks_benutting.csv')

