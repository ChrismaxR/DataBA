-- Aankomst- en ontslaglog: één rij per patiënt
-- Uniet alle log_aankomst_ontslag CSVs in output/
SELECT
  patient,
  TRY_CAST(aankomstTijdstip AS DOUBLE)              AS aankomstTijdstip,
  TRY_CAST(ontslagTijdstip AS DOUBLE)               AS ontslagTijdstip,
  TRY_CAST(duratieInZiekenhuis AS DOUBLE)           AS duratieInZiekenhuis,
  TRY_CAST(aankomstTijdstipReal AS TIMESTAMPTZ)::DATE AS simDag,
  aandoeningId,
  aandoeningOmschrijving,
  CASE WHEN TRY_CAST(ontslagTijdstip AS DOUBLE) IS NOT NULL THEN true ELSE false END AS isOntslagen
FROM read_csv_auto('../output/*_log_aankomst_ontslag.csv',
  union_by_name = true,
  types = {'ontslagTijdstip': 'VARCHAR', 'duratieInZiekenhuis': 'VARCHAR'})
