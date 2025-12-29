# Story 4 - Identificeer mogelijke datasets

## 🏆Op te leveren artefacten

- Een eerste beschrijving/schets van een ruwe data
- Buiten scope zijn aggregatie tabellen maar ruwe data moet aggregaties wel mogelijk maken
- Een eerste schets van een gegevensmodel
- Een eerste opzet van reverse engineering van Theme Hospital data.

### 👷‍♂️ Reverse Engineer Theme Hospital data

🦠 Overzicht ziektes:

|  Ziekten: |   |   |   |   |   |
|---|---|---|---|---|---|
| Broken Wind | Alien DNA  | Chronic Nosehair| Baldness  | Corrugated Ankles | Bloaty Head  | 
| Discrete Itching| Fractured Bones  | Gastric Ejections | Hairyitis  | Gut Rot | Jellyitis  | 
| Heaped Piles | Serious Radiation  | Invisibility | Slack Tongue  | Sleeping Illness | Broken Heart |
| The Squits | Golf Stones  | Transparency | Iron Lungs  | Uncommon Cold | Kidney Beans  | 
| 3rd Degree Sideburns | Ruptured Nodules  | Fake Blood | Spare Ribs  | Infectious Laughter | Unexpected Swelling  | 
| King Complex | Sweaty  | TV Personalities  | | | |                   


🏥 Overzicht kamer-typen

| Diagnose kamers | Behandelkamers | Klinieken | Faciliteiten |
|-----------------|----------------|-----------|--------------|
|  GP’s Office    |    Pharmacy    | Inflation Room | Toilets |
| General Diagnosis Room | Psychiatric Room | Decontamination| Staff Room|
| Cardiogram | The Ward | DNA Fixer | Research Department |
| Scanner | Operating Theatre | Hair Restoration |Training Room|
| Ultrascan |  | Slack Tongue Clinic | Waiting Room |
| Blood Machine |  | Fracture Clinic | |
| X-Ray | | Electrolysis | |
| The Ward | | Jelly Vat Waiting Room | |
| Psychiatric Room | |  | |

**Nota Bene:**
The Ward: diagnose + behandeling
Psychiatric Room: diagnose + behandeling
### 📊 Ruwe data

Benodigde data:

Twee fact-tabellen

### 🗺️ Gegevensmodel

![](./story4_datamodel.png)



