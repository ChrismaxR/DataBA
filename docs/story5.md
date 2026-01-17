# Story 5 - Bepaal data-generatieproces

## 🏆 Op te leveren artefacten:

1. Een definitie van scenarios is opgeleverd
2. Ideaaltypen voor scenarios zijn gedefinieerd, waarmee een eerste PoC kan worden gedaan op berekenen van de metrieken.
3. Een set van algemene constraints voor events is opgesteld.
4. Voor de event-tabel is een data dictionary aanwezig.

## ⭐️ Ideaaltypen voor event-tabel (ter voorbereiding op data genereren)

Er worden drie scenarios onderscheiden over wat een patient kan overkomen:

1. happyFlow - In dit scenario is er een benodigde diagnose/behandelkamer vrij, de patient hoeft nergens te wachten.
2. foutieveDiagnose - In dit scenario blijkt na de behandeling dat een patient een verkeerde diagnose heeft gekregen. De patiënt moet opnieuw gediagnostiseerd en behandeld worden (zie ook de story2.md en story2_model.png).  
3. kamerOnbeschikbaarheid - Drie situaties kunnen voor tijdelijke onbeschikbaarheid van een kamer zorgen

### happyFlow - normale flow - Behandelroute A

| eventId  | eventType            | datumTijd           | patientId  | kamerId  | kamerTypeId  |
|----------|----------------------|---------------------|------------|----------|--------------|
|  1       | aankomst             | 2025-01-01 13:24:00 | 1          | NULL     |  NULL        |
|  2       | inWachtrijReceptie   | 2025-01-01 13:24:00 | 1          | NULL     |  1           |
|  3       | inReceptie           | 2025-01-01 13:24:01 | 1          | 1        |  1           |
|  4       | inWachtrijDiagnose   | 2025-01-01 13:36:00 | 1          | NULL     |  2           |
|  5       | vrij                 | 2025-01-01 13:00:00 | NULL       | 6        |  2           |
|  6       | inDiagnose           | 2025-01-01 13:36:00 | 1          | 6        |  2           |
|  7       | inGebruik            | 2025-01-01 13:36:00 | 1          | 6        |  2           |
|  8       | inWachtrijBehandeling| 2025-01-01 14:00:00 | 1          | NULL     |  8           |
|  9       | vrij                 | 2025-01-01 14:00:00 | NULL       | 6        |  2           |
| 10       | vrij                 | 2025-01-01 14:34:00 | NULL       | 36       |  8           |
| 11       | inBehandeling        | 2025-01-01 14:00:00 | 1          | 36       |  8           |
| 12       | inGebruik            | 2025-01-01 14:00:00 | 1          | 36       |  8           |
| 13       | ontslagen            | 2025-01-01 15:00:00 | 1          | 36       |  8           |
| 14       | vrij                 | 2025-01-01 15:00:00 | NULL       | 36       |  8           |

### foutieveDiagnose - loop over diagnose & behandeling - Behandelroute A, terwijl behandelroute B correct is. 

| eventId  | eventType                   | datumTijd           | patientId  | kamerId  | kamerTypeId  |
|----------|-----------------------------|---------------------|------------|----------|--------------|
| 613      | aankomst                    | 2025-06-18 13:12:00 | 2865       | NULL     |  NULL        |
| 614      | inWachtrijReceptie          | 2025-06-18 13:12:00 | 2865       | NULL     |  1           |
| 615      | inReceptie                  | 2025-06-18 13:24:00 | 2865       | 2        |  1           |
| 616      | inWachtrijDiagnose          | 2025-06-18 13:36:00 | 2865       | NULL     |  2           |
| 617      | vrij                        | 2025-06-18 13:00:00 | NULL       | 7        |  2           |
| 618      | inGebruik                   | 2025-06-18 13:36:00 | 2865       | 7        |  2           |
| 619      | inWachtrijBehandeling       | 2025-06-18 14:00:00 | 2865       | NULL     |  8           |
| 620      | inDiagnose                  | 2025-06-18 13:46:00 | 2865       | 7        |  2           |
| 621      | vrij                        | 2025-06-18 14:00:00 | NULL       | 7        |  2           |
| 622      | vrij                        | 2025-06-18 14:34:00 | NULL       | 37       |  8           |
| 623      | inBehandeling               | 2025-06-18 14:10:00 | 2865       | 37       |  8           |
| 624      | inGebruik                   | 2025-06-18 14:10:00 | 2865       | 37       |  8           |
| 625      | inWachtrijNieuweDiagnose    | 2025-06-18 15:00:00 | 2865       | 37       |  8           |
| 626      | vrij                        | 2025-06-18 15:00:00 | NULL       | 37       |  8           |
| 627      | vrij                        | 2025-06-18 15:45:00 | NULL       | 5        |  2           |
| 628      | inNieuweDiagnose            | 2025-06-18 15:45:00 | 2865       | 5        |  2           |
| 629      | inWachtrijNieuweBehandeling | 2025-06-18 15:56:00 | 2865       | 5        |  2           |
| 630      | vrij                        | 2025-06-18 15:56:00 | NULL       | 5        |  2           |
| 631      | vrij                        | 2025-06-18 15:56:00 | NULL       | 16       | 10           |
| 632      | inNieuweBehandeling         | 2025-06-18 16:25:00 | 2865       | 16       | 10           |
| 633      | ontslagen                   | 2025-06-18 17:45:00 | 2865       | 16       | 10           |
| 634      | vrij                        | 2025-06-18 17:45:00 | NULL       | 16       | 10           |


### kamerOnbeschikbaarheid - technische mankementen, pauze en personeelstekort

In dit scenario zijn er situaties die ervoor zorgen dat kamers langer onbeschikbaar blijven dan normaal gesproken het geval zou zijn door patiëntbezoek. Drie situaties voor kamerOnbeschikbaarheid doen zich voor:

1. Medische apparatuur in de kamer is buiten werking door technisch mankementen. Deze mankementen moeten eerst verholpen worden voordat een volgende patiënt geholpen kan worden. In utils.R wordt per kamerType een maximale duur van een dergelijke situatie geconfigureerd.
2. Personeel in de kamer is met pauze: elke kamer is 2 keer per dag een half uur niet beschikbaar vanwege pauze. 
3. Heel sporadisch neemt een arts ontslag en moet een nieuwe arts worden geworven. Wanneer dit zich voordoet is een kamer 2 dagen niet beschikbaar. 

Zie hieronder voor hoe deze situaties in de event-tabel eruit zouden moeten zien:

### kamerOnbeschikbaarheid - technisch mankement van kamerapparatuur - eventType == "machineKapot"

| eventId  | eventType          | datumTijd           | patientId  | kamerId  | kamerTypeId  |
|----------|--------------------|---------------------|------------|----------|--------------|
| 10811    | vrij               | 2025-11-22 17:17:00 | NULL       | 31       |  13          |
| 10812    | machineKapot       | 2025-11-22 17:17:00 | NULL       | 31       |  13          |
| 10813    | vrij               | 2025-11-22 17:24:00 | NULL       | 31       |  13          |

### kamerOnbeschikbaarheid - pauze van personeel - eventType == "staffMetPauze"

| eventId  | eventType          | datumTijd           | patientId  | kamerId  | kamerTypeId  |
|----------|--------------------|---------------------|------------|----------|--------------|
| 51736    | vrij               | 2025-11-22 16:00:00 | NULL       | 24       |  9           |
| 51737    | staffMetPauze      | 2025-11-22 16:30:00 | NULL       | 24       |  9           |
| 51738    | vrij               | 2025-11-22 16:30:00 | NULL       | 24       |  9           |

### kamerOnbeschikbaarheid - personeel neemt ontslag - eventType == "staffOntslagGenomen"

| eventId  | eventType           | datumTijd           | patientId  | kamerId  | kamerTypeId  |
|----------|-------------------- |---------------------|------------|----------|--------------|
| 36       | vrij                | 2025-03-15 09:15:00 | NULL       | 34       |  17          |
| 37       | staffOntslagGenomen | 2025-03-15 09:15:00 | NULL       | 34       |  17          |
| 38       | vrij                | 2025-03-17 09:15:00 | NULL       | 34       |  17          |


## 🎛️ Eisen aan events

### Functionele eisen aan code voor genereren van event-tabel
- Periode waar de data over moet gaan is gelimiteerd. Dit wordt bepaald in utils.R
- Het Ziekenhuis is open op alle dagen van het jaar, ook in weekenden en op feestdagen.
- Openingstijden van het ziekenhuis zijn gelimiteerd. Dit wordt bepaald in utils.R
- Buiten de openingstijden wordt door het ziekenhuis geen werk voor patiënten verricht.
- Patiënten doorlopen dezelfde dag dat ze aankomen hun behandelroute. 
- Als een patiënt niet voor sluitingstijd is ontslagen (voor 21.00u), dan schuiven de resterende events door naar de eerst volgende mogelijkheid op de volgende dag na openingstijd 9.00u. 
- Aantal patiënten is een gelimiteerd aantal patiënten, dit wordt bepaald in utils.R.
- Aankomstdatum van patienten worden op X wijze verdeeld over het hele jaar
- Aankomstijd van patienten wordt op X wijze verdeeld op de dag.  
- Aantal kamers in het ziekenhuis wordt bepaald in Utils.R.
- Verdeling van deze kamers naar kamerType worden ook bepaald in Utils.R en blijven gedurende de hele simulatieperiode constant. Er kunnen van een kamerType meerdere binnen het ziekenhuis bestaan. Deze kamer zijn uniek door een kamerId. (zie Non-functionele eisen): zie Utils.R
- Er bestaan wachttijden voor Receptie, diagnosekamers en behandelkamers. Wachttijden worden bepaald door onbeschikbaarheid van een kamer. Als een kamer van het juiste kamerType beschikbaar komt, dan mag de patiënt
- Patiënten worden op volgorde van aankomst of plaatsing van een wachtrij geholpen: first in, first out.
- Er bestaan behandeltijden voor Receptie, diagnosekamers en behandelkamers (i.e. de duur dat een patiënt daadwerklijk in deze kamer wordt ingeschreven, gediagnostiseerd of behandeld). 
- In de scenarios (zie ook Utils.R) wordt bepaald onder welke scenarios patiënten in het ziekenhuis geholpen worden. 
- de duur dat een patiënt daadwerkelijk bij de receptie is; wordt gediagnostiseerd; en wordt behandeld is per kamerType bepaald in Utils.R (zie non-functionele eisen) 
- Patiënten krijgen maximaal maar 1 keer een verkeerde diagnose. Dat een patiënt verkeerd wordt gediagnostiseerd wordt bepaald in utils.R
- kamerOnbeschikbaarheid doet zich voor op kamerId niveau (individuele kamers)

### Non-functionele eisen aan code voor genereren van event-tabel
- naamconventie in tabellen en code (functies, objecten, enz) is camelCase. 
- naamconventie is zo uitgebreid mogelijk, zodat het helder is wat bedoeling van de code is. 
- code is van afdoende comments voorzien om uit te leggen wat de onderdelen in de code doen.
- uitgangspunt is R's Tidyverse, tenzij base R of andere packages beter werken
- ./data/generateScripts/utils.R bevat configuratie-informatie voor het genereren van de event data en dient gebruikt te worden: 
    - scenarios -> vector met mogelijke situaties die een patiënt kunnen treffen
    - datum_vector -> range van datums waarin patiëntbezoek plaatsvindt
    - tijd_vector -> range van tijdstippen waarin patiëntbezoeken op een dag plaatvinden
    - kamerDimensies -> configtabel voor receptie, diagnose- en behandelkamers, id's, 
    - aandoeningDimensies -> namen en id's van te behandelen aandoeningen
    - eventDimensies -> Tabel dat de verschillende eventTypes, categorisering en Id's bepaalt voor de te genereren event-tabel. 
    - patientenStamTabel -> hier worden de patiënten geïnitialiseerd (id's), welke a priori behandeling ze hebben en welk kamers voor diagnose en behandeling dienen te worden aangedaan.
- de generator moet unieke oplopende eventId's per patiënt genereren.

## 📖 Validatie van events

De volgende checks moeten het nakomen van de eisen valideren:
- de openingsuren komen overeen met de eis 
- geen overlap in gebruik per kamer door de tijd heen
- correcte event‑volgordes per patiënt per scenario
- een correcte scenario‑verdeling
- check op totaal aantal patiënten
-...

**NB** Hier nog bedenken of ik ook nog per kamerType en/of Aandoening een verdere verdieping wil maken. Zie ook [story #24](https://github.com/users/ChrismaxR/projects/3/views/18?sliceBy%5Bvalue%5D=Task&pane=issue&itemId=147606809&issue=ChrismaxR%7CDataBA%7C24)


## 📖 Data dictionary Configuratietabellen

#### AandoeningDimensies
| kolomnaam         | kolomOmschrijving                            | dataType     | nullable |
|-------------------|----------------------------------------------|--------------|----------|
| id                | Unieke id voor een event (PK)                | int          | F        |
| aandoeningOmschrijving | omschrijving van een aandoening zoals deze in Theme Hospital voorkomt | string       | F        |


#### kamerDimensies 
| kolomnaam              | kolomOmschrijving                            | dataType     | nullable |
|------------------------|----------------------------------------------|--------------|----------|
| kamerId                | Unieke id voor een kamer (PK)                | int          | F        |
| kamerTypeId            | Id voor een kamerType                        | int          | F        |
| kamerType              | Omschrijving van kamer (diagnose, behandel)  | string       | F        |
| volgendeVrijeDatumTijd | timestamp voor wanneer het volgende moment een kamerId vrij komt | dttm    | F        |
| minDuratieKamer        | minimale duratie van een bezoek aan een kamer in hele minuten    | int          | F        |
| maxDuratieKamer        | maximale duratie van een bezoek aan een kamer in hele minuten    | int          | F        |
| maxDuratieMankement    | minimale duratie van het verhelpen van een mankementen in een kamer in hele minuten | int          | F        |

#### patientenStamTabel 
| kolomnaam              | kolomOmschrijving                            | dataType     | nullable |
|------------------------|----------------------------------------------|--------------|----------|
| patientId              | Unieke id voor een patient (PK)              | int          | F        |
| aprioriAandoeningId    | Id voor een kamerType                        | int          | F        |
| behandelRoute          | Categorisering van diagnose-behandelroute    | string       | F        |
| diagnoseKamerTypeId    | vastlegging naar welke (diagnose)kamerType de patient dient aan te doen voor diens aandoening (FK) | int    | F        |
| behandelKamerTypeId    | vastlegging naar welke (behandel)kamerType de patient dient aan te doen voor diens aandoening (FK)  | int          | F        |
| patientScenario        | configuratie welk scenario een patiënt dient te doorlopen (happyFlow/foutieveDiagnose)  | string          | F        |
| juisteDiagnoseKamerId  | als patientScenario == "foutieveDiagnose dan wordt hier geconfigureerd welk kamerType voor herdiagnose benodigd is (FK) | int          | T       |
| juisteBehandelKamerId  | als patientScenario == "foutieveDiagnose dan wordt hier geconfigureerd welk kamerType voor herbehandeling benodigd is (FK) | int          | T       |

#### eventDimensies 
| kolomnaam              | kolomOmschrijving                            | dataType     | nullable |
|------------------------|----------------------------------------------|--------------|----------|
| id                     | Unieke id voor een eventDimensie (PK)        | int          | F        |
| eventType              | Typering van welke mogelijke events in de te genereren event-tabel mogen komen  | string          | F        |
| eventTypeCategorie     | Categorisering van types naar patiënt- en kamerevents  | string       | F        |


## 📖 Data dictionary Event tabel

#### event 
| kolomnaam         | kolomOmschrijving                            | dataType     | nullable |
|-------------------|----------------------------------------------|--------------|----------|
| eventId           | Unieke id voor een event (PK)                | int          | F        |
| eventType         | beschrijving van een event in het ziekenhuis | string       | F        |
| datumTijd         | DateTime stamp yyyy-mm-dd hh:mm:ss           | DateTime     | F        |
| patientId         | Id patient, niet uniek voor een event        | int          | T        |
| kamerId           | Id voor een speciefieke kamer, niet uniek    | int          | T        |
| kamerTypeId       | Id voor typeKamer, niet uniek                | int          | T        |

