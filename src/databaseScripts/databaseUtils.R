library(duckdb)

con <- dbConnect(
  drv = duckdb(),
  dbdir = "dashboard/sources/hospital/hospital.duckdb"
)


# set up datamodel tabellen --------------
# Droppen in omgekeerde afhankelijkheidsvolgorde: een tabel kan niet gedropt
# worden zolang een foreign key ernaar verwijst (fct_* -> dim_patient -> dim_aandoening).
dbExecute(con, "DROP TABLE IF EXISTS fct_gebeurtenis")
dbExecute(con, "DROP TABLE IF EXISTS fct_behandelkamer")
dbExecute(con, "DROP TABLE IF EXISTS dim_patient")
dbExecute(con, "DROP TABLE IF EXISTS dim_aandoening")
dbExecute(con, "DROP TABLE IF EXISTS dim_behandelkamer")

dbExecute(
  con,
  "CREATE TABLE dim_aandoening (
    id INTEGER PRIMARY KEY,
    aandoeningNaam TEXT NOT NULL
    )"
)

dbExecute(
  con,
  "CREATE TABLE dim_patient (
    id INTEGER PRIMARY KEY,
    aandoeningId INTEGER REFERENCES dim_aandoening (id)
    )"
)

dbExecute(
  con,
  "CREATE TABLE dim_behandelkamer (
    id INTEGER PRIMARY KEY,
    behandelkamerNaam TEXT NOT NULL,
    behandelkamerType TEXT
    )"
)

dbExecute(
  con,
  "CREATE TABLE fct_gebeurtenis (
    id INTEGER PRIMARY KEY,
    patientId INTEGER REFERENCES dim_patient (id),
    startTijdstip TIMESTAMP,
    eindTijdstip TIMESTAMP,
    behandeltijd DOUBLE,
    wachttijd DOUBLE,
    behandelkamerId INTEGER REFERENCES dim_behandelkamer (id),
    behandelkamerNummer INTEGER,
    simulatieRun INTEGER
    )"
)

# maxWachtrijOmvang en wachtrijLimiet zijn DOUBLE: simmer geeft hier Inf terug.
dbExecute(
  con,
  "CREATE TABLE fct_behandelkamer (
    id INTEGER PRIMARY KEY,
    tijdstip TIMESTAMP,
    behandelkamerId INTEGER REFERENCES dim_behandelkamer (id),
    patientenInBehandeling INTEGER,
    capaciteit INTEGER,
    patientenInWachtrij INTEGER,
    maxWachtrijOmvang DOUBLE,
    wachtrijLimiet DOUBLE,
    totaalPatientenBijBehandelkamer INTEGER,
    simulatieRun INTEGER
    )"
)

# write to datamodel tabellen --------------
# dbAppendTable i.p.v. dbWriteTable(overwrite = T): zo blijven de types en
# keys uit de CREATE-statements behouden. Dimensies voor facts i.v.m. foreign keys.
dbAppendTable(con, "dim_aandoening", dim_aandoening)
dbAppendTable(con, "dim_patient", dim_patient)
dbAppendTable(con, "dim_behandelkamer", dim_behandelkamer)
dbAppendTable(con, "fct_gebeurtenis", fct_gebeurtenis)
dbAppendTable(con, "fct_behandelkamer", fct_behandelkamer)

dbDisconnect(con)
