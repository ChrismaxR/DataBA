# Story 4 - Bepaal data-generatieproces

## 🏆 Op te leveren artefacten:

1. Ideaaltypen voor tabellen zijn gedefinieerd, waarmee een eerste PoC kan worden gedaan op berekenen van de metrieken.
2. Een vaste set van algemene constraints is opgesteld.
3. Een definitie van scenarios is opgeleverd
4. Voor de fct_event tabel is een data dictionary aanwezig.

## ⭐️ Ideaaltypen voor fct_event tabel (ter voorbereiding op data genereren)

### Easy flow - geen wachttijden - Scenario A

In dit scenario is er een benodigde diagnose/behandelkamer vrij, de patient hoeft nergens te wachten.

| event_id | event_type           | datumTijd           | patient_id | kamer_id | kamerType_id |
|----------|----------------------|---------------------|------------|----------|--------------|
|  1       | WachtenOpReceptie    | 2025-01-01 13:24:00 | 1          | NULL     |  1           |
|  2       | InReceptie           | 2025-01-01 13:24:00 | 1          | 1        |  1           |
|  3       | WachtenOpDiagnose    | 2025-01-01 13:36:00 | 1          | NULL     |  2           |
|  5       | Vrij                 | 2025-01-01 13:00:00 | NULL       | 6        |  2           |
|  4       | InGebruik            | 2025-01-01 13:36:00 | 1          | 6        |  2           |
|  6       | InDiagnose           | 2025-01-01 13:36:00 | 1          | 6        |  2           |
|  7       | WachtenOpBehandeling | 2025-01-01 14:00:00 | 1          | NULL     |  8           |
|  8       | Vrij                 | 2025-01-01 14:00:00 | NULL       | 6        |  2           |
|  9       | Vrij                 | 2025-01-01 14:34:00 | NULL       | 36       |  8           |
|  9       | InBehandeling        | 2025-01-01 14:00:00 | 1          | 36       |  8           |
| 10       | InGebruik            | 2025-01-01 14:00:00 | 1          | 36       |  8           |
| 11       | Ontslagen            | 2025-01-01 15:00:00 | 1          | 36       |  8           |
| 12       | Vrij                 | 2025-01-01 15:00:00 | NULL       | 36       |  8           |

### Medium flow - minimale wachttijden - Scenario A

In dit scenario is een benodigde diagnose/behandelkamer niet vrij, de patient heeft korte wachttijden.
- Wachttijden zijn kort tussen 0 en 10 minuten

| event_id | event_type           | datumTijd           | patient_id | kamer_id | kamerType_id |
|----------|----------------------|---------------------|------------|----------|--------------|
|  1       | WachtenOpReceptie    | 2025-01-01 13:12:00 | 2          | NULL     |  1           |
|  2       | InReceptie           | 2025-01-01 13:24:00 | 2          | 2        |  1           |
|  3       | WachtenOpDiagnose    | 2025-01-01 13:36:00 | 2          | NULL     |  2           |
|  5       | Vrij                 | 2025-01-01 13:00:00 | NULL       | 7        |  2           |
|  4       | InGebruik            | 2025-01-01 13:36:00 | 2          | 7        |  2           |
|  6       | InDiagnose           | 2025-01-01 13:46:00 | 2          | 7        |  2           |
|  7       | WachtenOpBehandeling | 2025-01-01 14:00:00 | 2          | NULL     |  8           |
|  8       | Vrij                 | 2025-01-01 14:00:00 | NULL       | 7        |  2           |
|  9       | Vrij                 | 2025-01-01 14:34:00 | NULL       | 37       |  8           |
|  9       | InBehandeling        | 2025-01-01 14:10:00 | 2          | 37       |  8           |
| 10       | InGebruik            | 2025-01-01 14:10:00 | 2          | 37       |  8           |
| 11       | Ontslagen            | 2025-01-01 15:00:00 | 2          | 37       |  8           |
| 12       | Vrij                 | 2025-01-01 15:00:00 | NULL       | 37       |  8           |

### Hard flow - minimale wachttijden - Scenario A

In dit scenario is een benodigde diagnose/behandelkamer niet vrij, de patient heeft korte wachttijden.
- Wachttijden zijn kort tussen 0 en 10 minuten

| event_id | event_type           | datumTijd           | patient_id | kamer_id | kamerType_id |
|----------|----------------------|---------------------|------------|----------|--------------|
|  1       | WachtenOpReceptie    | 2025-01-01 13:12:00 | 3036       | NULL     |  1           |
|  2       | InReceptie           | 2025-01-01 13:24:00 | 3036       | 2        |  1           |
|  3       | WachtenOpDiagnose    | 2025-01-01 13:36:00 | 3036       | NULL     |  2           |
|  5       | Vrij                 | 2025-01-01 13:00:00 | NULL       | 7        |  2           |
|  4       | InGebruik            | 2025-01-01 13:36:00 | 3036       | 7        |  2           |
|  6       | InDiagnose           | 2025-01-01 13:46:00 | 3036       | 7        |  2           |
|  7       | WachtenOpBehandeling | 2025-01-01 14:00:00 | 3036       | NULL     |  8           |
|  8       | Vrij                 | 2025-01-01 14:00:00 | NULL       | 7        |  2           |
|  9       | Vrij                 | 2025-01-01 14:34:00 | NULL       | 37       |  8           |
|  9       | InBehandeling        | 2025-01-01 14:10:00 | 3036       | 37       |  8           |
| 10       | InGebruik            | 2025-01-01 14:10:00 | 3036       | 37       |  8           |
| 11       | Ontslagen            | 2025-01-01 15:00:00 | 3036       | 37       |  8           |
| 12       | Vrij                 | 2025-01-01 15:00:00 | NULL       | 37       |  8           |

## 🎛️ Eisen aan events

### Functionele eisen aan code voor genereren van fct_event-tabel
- Periode waar de data over moet gaan: 2025
- Het Ziekenhuis is open op alle dagen van het jaar, ook in weekenden en op feestdagen.
- Openingstijden van het ziekenhuis: 9.00 - 21.00
- Buiten de openingstijden wordt door het ziekenhuis geen werk voor patiënten verricht.
- hoe omgaan met sluitingstijd? Overzetten naar volgende dag?
- Aantal patiënten is een gelimiteerd aantal patiënten (16463 patienten)
- Aankomstdatum van patienten worden op X wijze verdeeld over het hele jaar
- Aankomstijd van patienten wordt op X wijze verdeeld op de dag.  
- Aantal kamers: 32 en blijft constant gedurende het jaar
- Verdeling van deze kamers naar kamerType is ook constant en van tevoren vastgesteld. Er kunnen van een kamerType meerdere binnen het ziekenhuis bestaan. Deze kamer zijn uniek door een kamerId. (zie Non-functionele eisen): zie Utils.R
- Er bestaan wachttijden voor Receptie, diagnosekamers en behandelkamers. 
- Er bestaan behandeltijden voor Receptie, diagnosekamers en behandelkamers (i.e. de duur dat een patiënt daadwerklijk in deze kamer wordt ingeschreven, gediagnostiseerd of behandeld). 
- In de scenarios (zie ook Utils.R) wordt bepaald onder welke scenarios en voor welke kamerTypeId's en kamerTypes welke bandbreedtes zijn voor wachttijden. 
- Wachttijden worden vastgesteld per kamerType en kamerTypeId? ()-> realistischer dan algemeen wachttijden per scenario
- een kamer mag niet gebruikt worden als deze al bezet is door een andere patiënt. 
- de duur dat een patiënt daadwerkelijk bij de receptie is; wordt gediagnostiseerd; en wordt behandeld is ook per 
    - de duur van een receptie is 12 minuten
    - de duur van een diagnose is tussen de 20 en 30 minuten
    - de duur van een behandeling is tussen de 40 en 60 minuten
- De events die dienen voor te komen worden in utils.R uitgewerkt

### Non-functionele eisen aan code voor genereren van fct_event-tabel
- naamconventie in tabellen en code (functies, objecten, enz) is snakeCase. 
- naamconventie is zo uitgebreid mogelijk, zodat het helder is wat bedoeling van de code is. 
- code is van afdoende comments voorzien om uit te leggen wat de onderdelen in de code doen.
- uitgangspunt is R's Tidyverse, tenzij base R of andere packages beter werken
- ./data/generateScripts/utils.R bevat basis informatie voor het genereren van de fct_event data en dient gebruikt te worden: 
    - scenarios = 
    - scenarioParameters = 
    - kamers = 
    - datum_vector = 
    - tijd_vector = 
    - aandoeningen = 
    - patienten = 
    - events = 



## ✏️ Scenarios

|scenario | parameterType     | parameterSetting |
|---------|-------------------|------------------|
| Easy    | % records         |    70 %          |
| Easy    | wachtt. diag. min |     0 sec        |
| Easy    | wachtt. diag. max |    60 sec        |
| Easy    | wachtt. behn. min |     0 sec        |
| Easy    | wachtt. behn. max |    60 sec        |
| Easy    | kamer availability|   100 %          |
| Medium  | % records         |    20 %          |
| Medium  | wachtt. diag. min |     0 sec        |
| Medium  | wachtt. diag. max |   600 sec        |
| Medium  | wachtt. behn. min |     0 sec        |
| Medium  | wachtt. behn. max |   600 sec        |
| Medium  | kamer availability|    90 %          |
| Hard    | % records         |     5 %          |
| Hard    | wachtt. diag. min |   120 sec        |
| Hard    | wachtt. diag. max |  1500 sec        |
| Hard    | wachtt. behn. min |   120 sec        |
| Hard    | wachtt. behn. max |  1500 sec        |
| Hard    | kamer availability|    75 %          |
| Ultra   | % records         |     5 %          |
| Ultra   | wachtt. diag. min |   120 sec        |
| Ultra   | wachtt. diag. max |  1500 sec        |
| Ultra   | wachtt. behn. min |   120 sec        |
| Ultra   | wachtt. behn. max |  1500 sec        |
| Ultra   | kamer availability|    50 %          |

**NB** Hier nog bedenken of ik ook nog per kamerType en/of Aandoening een verdere verdieping wil maken. Zie ook [story #24](https://github.com/users/ChrismaxR/projects/3/views/18?sliceBy%5Bvalue%5D=Task&pane=issue&itemId=147606809&issue=ChrismaxR%7CDataBA%7C24)

## 📖 Data dictionary Event tabel

#### fct_event 
| kolomnaam         | kolomOmschrijving                            | dataType     |
|-------------------|----------------------------------------------|--------------|
| event_id          | Unieke id voor een event (PK)                | int          |
| event_type        | beschrijving van een event in het ziekenhuis | string       |
| datumTijd         | DateTime stamp yyyy-mm-dd hh:mm:ss           | DateTime     |
| patientId         | Id patient, niet uniek voor een event        | int          |
| kamerId           | Id voor een speciefieke kamer, niet uniek    | int          |
| kamerTypeId       | Id voor typeKamer, niet uniek                | int          |
