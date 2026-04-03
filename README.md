```
 /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$  /$$      /$$ /$$$$$$$$
| $$__  $$| $$_____/ /$$__  $$| $$__  $$| $$$    /$$$| $$_____/
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$$$  /$$$$| $$      
| $$$$$$$/| $$$$$   | $$$$$$$$| $$  | $$| $$ $$/$$ $$| $$$$$   
| $$__  $$| $$__/   | $$__  $$| $$  | $$| $$  $$$| $$| $$__/   
| $$  \ $$| $$      | $$  | $$| $$  | $$| $$\  $ | $$| $$      
| $$  | $$| $$$$$$$$| $$  | $$| $$$$$$$/| $$ \/  | $$| $$$$$$$$
|__/  |__/|________/|__/  |__/|_______/ |__/     |__/|________/
Theme Hospital • Wachttijden & Benutting dashboard                      
```
                                                                                                         
### 0.  Project management en setup

#### Governance
[Github project](https://github.com/users/ChrismaxR/projects/3/views/18?sliceBy%5Bvalue%5D=Epic)
[Github repo](https://github.com/ChrismaxR/DataBA/tree/main)

### 1.	Het probleem


### 2.	Waarom deze data?

- Theme Hospital ❤️ Wat was Theme Hospital ook al [weer](https://www.nme.com/features/gaming-features/why-theme-hospital-is-the-greatest-of-the-simulation-satires-3096680)?

> “De synthetische dataset is afgeleid van een discrete-event simulatie.
> Operationele afhankelijkheden (zoals kamerbeschikbaarheid) worden opgelost tijdens datageneratie.
> De fact-tabellen representeren analytische snapshots en zijn niet bedoeld als transactielog.”


### 3.	Architectuur (1 diagram, simple)

```mermaid
flowchart LR
    subgraph Configuratie["⚙️ Configuratie"]
        CFG["simmerConfig.R\n─────────────────\n• 20 kamers, capaciteit 5\n• 33 aandoeningen / 19 routes\n• Aankomst: 1–5 min interval\n• Werkdag: 09:00–17:00"]
    end

    subgraph Simulatie["🏥 Discrete-Event Simulatie  •  R + simmer"]
        SIM["simmerImplementatie.R\n─────────────────\n• Patiëntstromen modelleren\n• Wachtrijen per kamer\n• Werkdag-overloop logica\n• set.seed(42)"]
    end

    subgraph Verwerking["🔧 Statistieken & Wrangling  •  R + tidyverse"]
        STAT["simmerStatistics.R\n─────────────────\n• Wachttijd berekenen\n• Tijdstempels mappen\n• Bezettingsgraad aggregeren"]
        WRITE["simmerWriteToDisk.R"]
    end

    subgraph Opslag["💾 Output  •  CSV"]
        CSV1["events_wrangle.csv\n(~320K rijen)"]
        CSV2["log_aankomst_ontslag.csv\n(~86K rijen)"]
        CSV3["tabel_benutting.csv\n(20 kamers)"]
    end

    subgraph Analytics["🦆 In-Memory Analytics  •  DuckDB"]
        SQL["SQL queries\n(lees CSVs via read_csv_auto)"]
    end

    subgraph Dashboard["📊 BI Dashboard  •  Evidence.dev"]
        P1["Overzicht\n(KPIs, instroom)"]
        P2["Capaciteit\n(bezettingsgraad)"]
        P3["Wachtrijen\n(wachttijden)"]
        P4["Ziekteverloop\n(verblijfsduur)"]
    end

    CFG --> SIM
    SIM --> STAT
    STAT --> WRITE
    WRITE --> CSV1 & CSV2 & CSV3
    CSV1 & CSV2 & CSV3 --> SQL
    SQL --> P1 & P2 & P3 & P4
```

### 4.	Key metrics & assumptions

### 5.	Dashboard screenshots(gif?)

### 6.	What I would improve with more time

- predictive modelling
- seasonal influences on utilization and queue length
- epidemic simulation
- priority queueing - patiënten met een hogere prioriteit (zoals ongelukken en noodgevallen)
- multiple stakeholders with conflicting interests
- scenarios bouwen: wat als we meer kamers hadden gehad/meer patiënten te verstouwen hadden gehad, enz.