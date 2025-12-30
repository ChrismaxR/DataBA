# Story 4 - Bepaal data-generatieproces

## 🏆 Op te leveren artefacten:

1. Voor elke tabel is een data dictionary aanwezig.
2. Ideaaltypen voor tabellen zijn gedefinieerd, waarmee een eerste PoC kan worden gedaan op berekenen van de metrieken.
3. Een vaste set van algemene constraints is opgesteld.
4. Een definitie van scenarios is opgeleverd

## 📖 Data dictionaries

## ⭐️ Ideaaltypen voor tabellen

## 🎛️ Algemene constraints

#### fct_patient constraints:
 1. id is altijd uniek en de Primary Key
 2. patientId geldt voor alle regels die dezelfde patient betreffen
 3. datumTijd heeft als format yyyy-mm-dd hh:mm:ss
 4. datumAankomst heeft als format yyyy-mm-dd en is altijd gelijk of kleiner dan date(datumTijd)
 5. diagnoseId hoeft niet gevuld te zijn (in het geval dat patient nog niet gediagnosticeerd is)
 6. diagnoseId is pas gevuld als behandelStatus in ("WachtenOpBehandeling", "InBehandeling", "Ontslagen", "WachtenOpNieuweDiagnose")
 7. behandelStatus altijd een van de string literals uit de enumeratie "behandelStatus"
 8. Als behandelstatus in ("WachtenOpReceptie", "InReceptie") dan is diagnoseId altijd NULL
 9. ...
10. ...

#### dim_diagnose constraints:
1. Combinatie fct_patient.behandelstatus & fct_patient.diagnoseId bepaalt samen dim_diagnose.kamerTypeId (vastgelegd in dim_diagnose)
2. Als diagnoseId IS NULL, dan is de bijbehorende diagnoseOmschrijving altijd "Nog Geen Diagnose"
3. diagnoseOmschrijving is altijd een van de string literals uit de bijbehorende enumeratie "diagnoseOmschrijving"
 
#### fct_kamer constraints:
1. id is altijd uniek en de Primary key
2. kamerId geldt voor alle regels die dezelfde kamer betreffen
3. datumTijd heeft als format yyyy-mm-dd hh:mm:ss
4. kamerTypeId is een Foreign key en verwijst naar dim_kamerType.id
5. kamerStatus altijd een van de string literals uit de bijbehorende enumeratie "kamerStatus"

#### dim_kamerType:
1. id is altijd uniek en de Primary key
2. kamerType altijd een van de string literals uit de bijbehorende enumeratie "kamerType"

## ✏️ Scenarios

Easy
Altijd kamers beschikbaar, geen tot minimale wachttijden
% records


Medium -> Geen kamers beschikbaar, kortere wachttijden

Hard -> Geen kamers beschikbaar, langere wachttijden

Ultra hard -> Hard, maar ook met foute diagnoses