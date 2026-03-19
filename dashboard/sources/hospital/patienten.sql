-- Aankomst- en ontslaglog: één rij per patiënt
-- Uniet alle log_aankomst_ontslag CSVs in output/
SELECT
  patient,
  aankomstTijdstip::DOUBLE                          AS aankomstTijdstip,
  ontslagTijdstip::DOUBLE                           AS ontslagTijdstip,
  duratieInZiekenhuis::DOUBLE                       AS duratieInZiekenhuis,
  TRY_CAST(aankomstTijdstipReal AS TIMESTAMPTZ)::DATE AS simDag,
  aandoeningId,
  aandoeningOmschrijving,
  CASE WHEN ontslagTijdstip IS NOT NULL THEN true ELSE false END AS isOntslagen
FROM read_csv_auto('../output/*_log_aankomst_ontslag.csv', union_by_name = true)
