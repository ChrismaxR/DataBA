library(duckdb)

con <- dbConnect(
  drv = duckdb(),
  dbdir = here::here("dashboard", "sources", "hospital", "hospital.duckdb")
)


# source: https://r.duckdb.org

# set up duckdb tables --------------
dbExecute(
  con,
  "CREATE TABLE totaal (
    behandelkamers INT,
    aandoeningen INT,
    patienten INT,
    gemiddeldeBehandeltijdMin DOUBLE,
    gemiddeldeWachttijdMin DOUBLE,
    mediaanWachttijdMin DOUBLE
    )"
)

dbExecute(
  con,
  "CREATE TABLE aankomstOntslag (
    maand DATE,
    maandLabel TEXT,
    ontslagen TEXT,
    aandoeningOmschrijving TEXT,
    patienten INT,
    gemiddeldeTijdInZiekenhuisMin DOUBLE
  )"
)

dbExecute(
  con,
  "CREATE TABLE capaciteit (
    maand DATE,
    maandLabel TEXT,
    kamer TEXT,
    totaleBehandeltijdMin DOUBLE,
    benuttingPerc DOUBLE,
    wachttijdMin DOUBLE,
    patientenBehandeld INT,
    gemiddeldeBehandeltijdPerPatientMin DOUBLE,
    gemiddeldeWachttijdPerPatientMin DOUBLE
    )"
)

dbExecute(
  con,
  "CREATE TABLE behandeltijd (
    maand DATE,
    maandLabel TEXT,
    kamerType TEXT,
    aandoening TEXT,
    patientenBehandeld INT,
    somBehandeltijdMin DOUBLE,
    gemBehandeltijdMin DOUBLE,
    mediaanBehandeltijdMin DOUBLE
    )"
)

## Remove tabels
# dbRemoveTable(conn = con, name = "aankomstOntslag")

# write to duckdb tables --------------

dbWriteTable(
  conn = con,
  "totaal",
  totaal,
  append = F,
  overwrite = T
)

dbWriteTable(
  conn = con,
  "aankomstOntslag",
  aankomst_onstlag,
  append = F,
  overwrite = T
)

dbWriteTable(
  conn = con,
  "capaciteit",
  capaciteitMaandResourceKamerNummer,
  append = F,
  overwrite = T
)

dbWriteTable(
  conn = con,
  "behandeltijd",
  behandeltijdMaandResourceAandoening,
  append = F,
  overwrite = T
)

# check of tabellen gevuld zijn ----------------------
# dbReadTable(con, "totaal")
# dbReadTable(con, "aankomstOntslag")
# dbReadTable(con, "capaciteit")
# dbReadTable(con, "behandeltijd")

dbDisconnect(con)
