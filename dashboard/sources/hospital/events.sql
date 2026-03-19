-- Wrangled event log: één rij per patiënt-resource combinatie
-- Uniet alle events_wrangle CSVs in output/ (meerdere simulatieruns worden gecombineerd)
SELECT
  name,
  resource,
  activityTime::DOUBLE  AS activityTime,
  waitTime::DOUBLE      AS waitTime,
  TRY_CAST(startTimeReal AS TIMESTAMPTZ)::DATE AS simDag
FROM read_csv_auto('../output/*_events_wrangle.csv', union_by_name = true)
