# Story 4 - Identificeer mogelijke datasets

## 🏆 Op te leveren artefacten

- Een eerste beschrijving/schets van een ruwe data
- Buiten scope zijn aggregatie tabellen maar ruwe data moet aggregaties wel mogelijk maken
- Een eerste opzet van reverse engineering van Theme Hospital data.
- Een eerste schets van een gegevensmodel

### 👷‍♂️ Reverse Engineer Theme Hospital data

#### 🏥 Overzicht kamer-typen

| Diagnose kamers        | Behandelkamers    | Klinieken           | Faciliteiten |
|------------------------|-------------------|---------------------|--------------|
| GP’s Office            | Pharmacy          | Inflation Room      | Toilets      |
| General Diagnosis Room | Psychiatric Room  | Decontamination     | Staff Room   |
| Cardiogram             | The Ward          | DNA Fixer           | Research Dept|
| Scanner                | Operating Theatre | Hair Restoration    | Training Room|
| Ultrascan              |                   | Slack Tongue Clinic | Waiting Room |
| Blood Machine          |                   | Fracture Clinic     |              |
| X-Ray                  |                   | Electrolysis        |              |
| The Ward               |                   | Jelly Vat           |              |
| Psychiatric Room       |                   |                     |              |

**Nota Bene:** In het spel geldt:
The Ward: diagnose + behandeling
Psychiatric Room: diagnose + behandeling

#### 🦠 Aandoeningen Behandelroutes voor patiënten

| id  | aandoening           | aanmelden  | diagnose    (kamerId) | behandeling        (kamerId) | behandelroute |
|-----|----------------------|------------|-----------------------|------------------------------|----------|
|  1  | Sleeping Illness     | receptie   | GP's Office       (2) | The Ward                ( 8) | A        |
|  2  | Discrete Itching     | receptie   | GP's Office       (2) | The Ward                ( 8) | A        |
|  3  | Fake Blood           | receptie   | GP's Office       (2) | The Ward                ( 8) | A        |
|  4  | The Squits           | receptie   | GP's Office       (2) | Pharmacy                (10) | B        |
|  5  | Sweaty Palms         | receptie   | GP's Office       (2) | Pharmacy                (10) | B        |
|  6  | Gastric Ejections    | receptie   | GP's Office       (2) | Pharmacy                (10) | B        |
|  7  | Uncommon Cold        | receptie   | GP's Office       (2) | Pharmacy                (10) | B        |
|  8  | Chronic Nosehair     | receptie   | GP's Office       (2) | Electrolysis            (18) | C        |
|  9  | Hairyitis            | receptie   | GP's Office       (2) | Electrolysis            (18) | C        |
| 10  | Baldness             | receptie   | GP's Office       (2) | Hair Restoration Clinic (14) | D        |
| 11  | King Complex         | receptie   | GP's Office       (2) | Psychiatric Room        ( 9) | E        |
| 12  | Infectious Laughter  | receptie   | GP's Office       (2) | Psychiatric Room        ( 9) | E        |
| 13  | TV Personalities     | receptie   | GP's Office       (2) | Psychiatric Room        ( 9) | E        |
| 14  | Ruptured Nodules     | receptie   | General Diagnosis (3) | Operating Theatre       (11) | F        |
| 15  | Broken Wind          | receptie   | General Diagnosis (3) | Operating Theatre       (11) | F        |
| 16  | Golf Stones          | receptie   | General Diagnosis (3) | Operating Theatre       (11) | F        |
| 17  | Iron Lungs           | receptie   | General Diagnosis (3) | Operating Theatre       (11) | F        |
| 18  | Gut Rot              | receptie   | General Diagnosis (3) | Pharmacy                (10) | G        |
| 19  | Heaped Piles         | receptie   | General Diagnosis (3) | Pharmacy                (10) | G        |
| 20  | 3rd Degree Sideburns | receptie   | General Diagnosis (3) | Electrolysis            (18) | H        |
| 21  | Bloaty Head          | receptie   | General Diagnosis (3) | Inflation Room          (12) | I        |
| 22  | Slack Tongue         | receptie   | General Diagnosis (3) | Slack Tongue Clinic     (16) | J        |
| 23  | Broken Heart         | receptie   | Cardiogram        (4) | Fracture Clinic         (17) | K        |
| 24  | Spare Ribs           | receptie   | X-Ray             (7) | Fracture Clinic         (17) | L        | 
| 25  | Corrugated Ankles    | receptie   | X-Ray             (7) | Fracture Clinic         (17) | L        |
| 26  | Fractured Bones      | receptie   | X-Ray             (7) | Fracture Clinic         (17) | L        |
| 27  | Kidney Beans         | receptie   | X-Ray             (7) | Operating Theatre       (11) | M        | 
| 28  | Unexpected Swelling  | receptie   | X-Ray             (7) | Pharmacy                (10) | N        |
| 29  | Serious Radiation    | receptie   | X-Ray             (7) | Decontamination Room    (20) | O        |
| 30  | Jellyitis            | receptie   | Scanner           (5) | Jelly Vat               (19) | P        |
| 31  | Transparency         | receptie   | Scanner           (5) | Pharmacy                (10) | Q        |
| 32  | Invisibility         | receptie   | Ultrascan         (6) | Pharmacy                (10) | R        |
| 33  | Alien DNA            | receptie   | Ultrascan         (6) | DNA Fixer               (13) | S        |

**NB** Dit is versimpeld ten op zichte van het echte spel, want daar kunnnen meerdere diagnose stappen zitten voordat een patiënt bij een behandelkamer uitkomt, maar ik voorzie dat dit te veel complexiteit oplevert in dit project. Ik heb daarom hier een vrije en versimpelde interpretatie gemaakt. 

Hier volgt ook uit een aantal scenarios die ik op kan zetten die een gemeenschappelijk verloop kennen, hiervoor 

### 🗺️ Analytische datamodel t.b.v. snapshot data

![](./png/story4_datamodel.png)

### 📊 Conceptuele metrieken in relatie tot het analytische datamodel

|  id | onderwerp  | operationalisatie                       | pseudoCode                                                                       | inDataModel? |
|-----|------------|-----------------------------------------|----------------------------------------------------------------------------------|--------------|
|   1 | Capaciteit |  # potentiële te benutten behandelkamers| count(fct_kamer.id) where fct_kamer.kamerStatus == "InGebruik"                   |  True        |
|   2 | Capaciteit |  # behandelkamers met kapotte mach.     | count(fct_kamer.id) where fct_kamer.kamerStatus == "MachineKapot"                |  True        |
|   3 | Capaciteit |  # behandelkamers zonder personeel      | count(fct_kamer.id) where fct_kamer.kamerStatus == "Pauze/Ontslag"               |  True        |
|   4 | Capaciteit |  Breakdown zonder pers. (pauze/ontslag) | group by(kamerStatus == "Pauze"/"Ontslag")                                       |  True        |
|   5 | Ziekte     |  # patiënten                            | count(fct_patient.id) where fct_patient.behandelStatus != "Ontslagen"            |  True        |
|   6 | Ziekte     |  # patiënten per specialisme            | zelfde als id = 5 + group by(behaldelkamerId)                                    |  True        |
|   7 | Ziekte     |  # patiënten met/zonder diagnose        | count(fct_patient.id) where fct_patient.behandelStatus != "WachtenOpDiagnose"    |  True        |
|   8 | Ziekte     |  # patiënten met diagnose               | zelfde als id = 7 where fct_patient.behandelStatus == "WachtenOpBehandeling"     |  True        |
|   9 | Queue      |  # patiënten aan het wachten            | count(fct_patient.id) where str_detect(fct_patient.behandelStatus, "^Wachten")   |  True        |
|  10 | Queue      |  Gem. tijd in de wacht                  | Δfct_patient.datumTijd between fct_patient.behandelStatus in ("^Wachten"/ "^In)  |  True        |
|  11 | Queue      |  Gem. tijd in de wacht per specialisme  | zelfde als id = 10 + group by dim_diagnose.kamerTypeId                           |  True        |
|  12 | Benutting  |  Tijd per tijdseenheid kamer in gebruik | Δfct_kamer.datumTijd between fct_kamer.kamerStatus                               |  True        |
|  13 | Benutting  |  Benuttingsgraad per specialisme        | zelfde als id = 12 + group by fct_kamer.kamerTypeId                              |  True        | 

De pseudocode helpt al een beeld vormen van wat voor queries ik denkstraks nodig te hebben voor het echte data wrangle-werk. 

### 🧭 Benodigde ruwe data om te simuleren: procesdata

#### Probleem: ik moet tegelijkertijd fct_patient en fct_kamer genereren, maar dat is problematisch. 

- fct_patient kan niet onafhankelijk bestaan; er is een afhankelijkheid van fct_kamer, want een patiëntstatus verandert alleen als:
	•	een kamer beschikbaar is
	•	met een bepaald kamerType
	•	op een bepaald datumTijd

- Capaciteit in de vorm van beschikbare kamers in fct_kamer is afhankelijk van fct_patient, kamerstatus verandert alleen als:
	•	een patient beschikbaar is
	•	met een bepaald behandelStatus
	•	op een bepaald datumTijd

> Er is sprake van een **bidirectionele** relatie, waarbij ook nog een tijdscomponent centraal staat; causaliteit is niet (eenvoudig) correct te modelleren met Foreign Keys tussen beide tabellen. 

#### Oplossing: introduceer een simulatielaag onder de analystische laag (mijn datamodel) met een fct-event en leid de analytische laag daaruit af.  

Effectief maak ik drie lagen:

1. Simulatielaag -> Wat gebeurt wanneer?
2. Event-laag -> Wat is er gebeurd? En op welk tijdstip?
3. Analytische laag -> Op welke wijze moeten feiten uit de events afgeleid en geaggregeerd worden? 

Voordelen:
1. Event-driven -> verbetert realisme
2. Facts -> Feitelijkheden maken analyse zuiver
3. Geen **bidirectionele dependencies**: tijd is de verbindende sleutel; niet id's. 

> We gaan van events naar snapshots van die events

#### event tabel
- event_id
- event_type
- datumTijd
- patient_id (nullable)
- kamer_id (nullable)
- kamerType_id

event.eventTypes:

patientEvents:

- WachtenOpReceptie
- InReceptie
- WachtenOpDiagnose
- InDiagnose
- WachtenOpBehandeling
- InBehandeling
- Ontslagen
- WachtenOpNieuweDiagnose

behandelkamerEvents:
- Vrij
- InGebruik
- MachineKapot
- StaffMetPauze
- StaffOntslagGenomen

event.datumTijd: 
- alleen tijdstippen mogelijk tussen 9:00 en 21.00u, want alleen dan wordt er gewerkt. 
- voor Behandelkamers geldt:
	- receptieduur is 15 min. 
	- diagnose duurt 30 min. 
	- behandeling duurt 60 min. 
- daarmee zijn er dagelijks potentieel, als we van alle kamers er 1 hebben:
	- 50 receptieslots
	- 25 diagnoseslots
	- 12,5 behandelslots