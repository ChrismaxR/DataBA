-- Benutting per kamertype: pakt de meest recente tabel_benutting CSV
-- Herberekent benutting op basis van werkuren (5 dagen × 480 min/dag per server)
SELECT *
FROM read_csv_auto('../output/*_tabel_benutting.csv', filename = true, union_by_name = true)

