-- Benutting per kamertype: pakt de meest recente tabel_benutting CSV
-- Herberekent benutting op basis van werkuren (5 dagen × 480 min/dag per server)
SELECT
  resource,
  sumWaitTime::DOUBLE    AS sumWaitTime,
  sumActivityTime::DOUBLE AS sumActivityTime,
  capacity::INTEGER      AS capacity,
  -- Werkuren-gecorrigeerde benutting (onafhankelijk van simDuration-waarde in CSV)
  sumActivityTime / (capacity * 5 * 480) AS utilization
FROM read_csv_auto('../output/*_tabel_benutting.csv', filename = true, union_by_name = true)
QUALIFY ROW_NUMBER() OVER (PARTITION BY resource ORDER BY filename DESC) = 1
