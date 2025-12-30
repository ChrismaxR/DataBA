# Story 3 - Definieer succescriteria voor Dataproduct

## 🏆 Op te leveren artefacten:

1. Concepten van metrieken
2. Een eerste opzet van een dataproduct: een dashboard

### Informatiebehoefte van Marieke:
1. Wat zijn wachttijden in mijn ziekenhuis? 
2. Wat is de benuttingsgraad van mijn behandelkamers in mijn ziekenhuis?
3. Is de verhouding met mijn zorgcapaciteit in balans?
4. Hoe ontwikkelt benutting door de tijd?
5. Hoe ontwikkelt capaciteit zich door de tijd?
6. Welke tools heb ik om eventuele problemen te voorkomen?
7. Kan ik benutting en capaciteit modelleren om forecasts te draaien?


## 📈 Concepten van Metrieken

1. Capaciteit: 
    - \# behandelkamers in potentie te benutten zijn.
    - \# behandelkamers met kapotte machine
    - \# behandelkamers zonder personeel 
        - vacature vs. "met pauze"
2. Ziekteverloop: 
    - \# patiënten
    - \# patiënten per specialisme
    - \# patiënten zonder diagnose
    - \# gediagnosticeerde patiënten
3. Queue Length:
    - \# patiënten nog niet behandeld (status = waiting)
    - Gem. wachttijd -> vraag is er weging per specialisme nodig (bv. ernst van de ziekte, of hoeveelheid patiënten per ziekte)?
    - Gem. wachttijd per specialisme
4. Benuttingsgraad (Nice to have!):
    - Tijd per tijdseenheid dat een kamer in gebruik is.
    - Benuttingsgraad per specialisme

## 🖥️ Opzet dashboard

### Tab 1: "Main"

Statische big values van afgelopen maand:
1. \# nieuwe patiënten deze maand
2. \# patiënten nog niet behandeld deze maand (status = waiting)
3. Gem. wachttijd deze maand - overall

Nice to have: een vergelijk met vorige maand + trendlijn

Grafiek 1: Ontwikkeling toeloop van patiënten per maand voor afgelopen jaar
Grafiek 2: Gemiddelde wachttijd per specialisme (top 10)

### Tab 4: Queue Length

Big values:
1. \# patiënten nog niet behandeld (status = waiting)
2. Gem. overall wachttijd afgelopen jaar

Grafieken:
1. Gem. wachttijd per specialisme, ontwikkeling per maand over afgelopen jaar

### Tab 3: Capaciteit

Big values:
1. Huidige aantal behandelkamers
2. Huidige aantal behandelkamers die out of order zijn
3. Pauzes tellen per maand
4. Overall benuttingsgraad van behandelkamers

Grafieken:
1. Ontwikkeling beschikbare behandelkamers per kamerType
2. Benuttingsgraden per kamerType

### Tab 4: Ziekteverloop

Big values:
1. \# patiënten
2. \# patiënten per specialisme
3. \# patiënten zonder diagnose
4. \# gediagnosticeerde patiënten

Grafieken:
1. Verloop van vier metrieken over afgelopen jaar
