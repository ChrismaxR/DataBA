# Story 4 - Bepaal data-generatieproces

## 🏆 Op te leveren artefacten:

1. Voor elke tabel is een data dictionary aanwezig.
2. Ideaaltypen voor tabellen zijn gedefinieerd, waarmee een eerste PoC kan worden gedaan op berekenen van de metrieken.
3. Een vaste set van algemene constraints is opgesteld.
4. Een definitie van scenarios is opgeleverd

## 📖 Data dictionaries

#### fct_event (simulatie laag)
| kolomnaam         | kolomOmschrijving                            | dataType     |
|-------------------|----------------------------------------------|--------------|
| event_id          | Unieke id voor een event (PK)                | int          |
| event_type        | beschrijving van een event in het ziekenhuis | string       |
| datumTijd         | DateTime stamp yyyy-mm-dd hh:mm:ss           | DateTime     |
| patientId         | Id patient, niet uniek voor een event        | int          |
| kamerId           | Id voor een speciefieke kamer, niet uniek    | int          |
| kamerTypeId       | Id voor typeKamer, niet uniek                | int          |


#### fct_patient
| kolomnaam         | kolomOmschrijving                            |
|-------------------|----------------------------------------------|
| id                | Uniek patiënt id  (PK)                       |
| patientId         | id voor een patient, niet uniek voor een event |
| datumTijd         | DateTime stamp yyyy-mm-dd hh:mm:ss           |
| datumAankomst     | Datum |
| behandelStatus    | |
| diagnoseId        | |

#### fct_kamer
| kolomnaam         | kolomOmschrijving                            |
|-------------------|----------------------------------------------|
| id                | |
| kamerId           | |
| datumTijd         | |
| kamerTypeId       | |
| kamerStatus       | |
 
#### dim_diagnose
| kolomnaam            | kolomOmschrijving                            |
|----------------------|----------------------------------------------|
| id                   | |
| diagnoseOmschrijving | |
| kamerTypeId          | |

#### dim_kamerType 
| kolomnaam         | kolomOmschrijving                            |
|-------------------|----------------------------------------------|
| id                | |
| kamerType         | |


## ⭐️ Ideaaltypen voor fct_event tabel (ter voorbereiding op generatie)

### Easy flow - geen wachttijden - Scenario A

In dit scenario is er een benodigde diagnose/behandelkamer vrij, de patient hoeft nergens te wachten.
| event_id     | event_type             | datumTijd           | patient_id    | kamer_id   | kamerType_id |
|--------------|------------------------|---------------------|---------------|------------|--------------|
|  1           | WachtenOpReceptie      | 2025-01-01 13:24:00 | 1             | NULL       |  1           |
|  2           | InReceptie             | 2025-01-01 13:24:00 | 1             | 1          |  1           |
|  3           | WachtenOpDiagnose      | 2025-01-01 13:36:00 | 1             | NULL       |  2           |
|  5           | Vrij                   | 2025-01-01 13:00:00 | NULL          | 6          |  2           |
|  4           | InGebruik              | 2025-01-01 13:36:00 | 1             | 6          |  2           |
|  6           | InDiagnose             | 2025-01-01 13:36:00 | 1             | 6          |  2           |
|  7           | WachtenOpBehandeling   | 2025-01-01 14:00:00 | 1             | NULL       |  8           |
|  8           | Vrij                   | 2025-01-01 14:00:00 | NULL          | 6          |  2           |
|  9           | Vrij                   | 2025-01-01 14:34:00 | NULL          | 36         |  8           |
|  9           | InBehandeling          | 2025-01-01 14:00:00 | 1             | 36         |  8           |
| 10           | InGebruik              | 2025-01-01 14:00:00 | 1             | 36         |  8           |
| 11           | Ontslagen              | 2025-01-01 15:00:00 | 1             | 36         |  8           |
| 12           | Vrij                   | 2025-01-01 15:00:00 | NULL          | 36         |  8           |

### Medium flow - minimale wachttijden - Scenario A

In dit scenario is een benodigde diagnose/behandelkamer niet vrij, de patient heeft korte wachttijden.
- Wachttijden zijn kort tussen 0 en 10 minuten

| event_id     | event_type             | datumTijd           | patient_id    | kamer_id   | kamerType_id |
|--------------|------------------------|---------------------|---------------|------------|--------------|
|  1           | WachtenOpReceptie      | 2025-01-01 13:12:00 | 2             | NULL       |  1           |
|  2           | InReceptie             | 2025-01-01 13:24:00 | 2             | 2          |  1           |
|  3           | WachtenOpDiagnose      | 2025-01-01 13:36:00 | 1             | NULL       |  2           |
|  5           | Vrij                   | 2025-01-01 13:00:00 | NULL          | 7          |  2           |
|  4           | InGebruik              | 2025-01-01 13:36:00 | 1             | 7          |  2           |
|  6           | InDiagnose             | 2025-01-01 13:46:00 | 1             | 7          |  2           |
|  7           | WachtenOpBehandeling   | 2025-01-01 14:00:00 | 1             | NULL       |  8           |
|  8           | Vrij                   | 2025-01-01 14:00:00 | NULL          | 7          |  2           |
|  9           | Vrij                   | 2025-01-01 14:34:00 | NULL          | 37         |  8           |
|  9           | InBehandeling          | 2025-01-01 14:10:00 | 1             | 37         |  8           |
| 10           | InGebruik              | 2025-01-01 14:10:00 | 1             | 37         |  8           |
| 11           | Ontslagen              | 2025-01-01 15:00:00 | 1             | 37         |  8           |
| 12           | Vrij                   | 2025-01-01 15:00:00 | NULL          | 37         |  8           |

## 🎛️ Algemene constraints

Periode: 2025
Aantal patiënten: 16463 totaal over 2025
Aantal kamers: 32 en is constant
Verdeling kamers:

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

#### dim_kamerType constraints:
1. id is altijd uniek en de Primary key
2. kamerType altijd een van de string literals uit de bijbehorende enumeratie "kamerType"

## ✏️ Scenarios

#### Easy: altijd kamers beschikbaar, geen tot minimale wachttijden

| parameterType     | parameterSettings  |
|-------------------|--------------------|
| % records         |   70%              |
| kamerAvailability |  100%              |

#### Medium: Geen kamers beschikbaar, kortere wachttijden
| parameterType     | parameterSettings  |
|-------------------|--------------------|
| % records         |   20%              |
| kamerAvailability |  80-95%            |

#### Hard -> Geen kamers beschikbaar, langere wachttijden
| parameterType     | parameterSettings  |
|-------------------|--------------------|
| % records         |    5%              |
| kamerAvailability |  70-80%            |

#### Ultra hard -> Hard, maar ook met foute diagnoses (dus met feedback loop)
| parameterType     | parameterSettings  |
|-------------------|--------------------|
| % records         |    5%              |
| kamerAvailability |  70-80%            |