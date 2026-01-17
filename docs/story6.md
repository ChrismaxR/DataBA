# Story 6 - Data initieel genereren

## 🏆 Op te leveren artefacten:

- concept simmer implementatie dat voldoet aan eisen uit story 5
- configuratiescript om simulatie te kunnen tweaken - voor interessante scenarios
- een eerste event tabel dat in lijn is met eisen aan events (story 5)
- een eerste concept van statitieken t.b.v. validatie en poc voor dashboard

## 🎛️ Eisen aan event-data uit story5.md

### Functionele eisen (event-generatie)

| Categorie | Eis |
|----------|-----|
| Periode & tijd | De simulatieperiode is begrensd en geconfigureerd in `utils.R`. |
| Openingstijden | Het ziekenhuis is dagelijks open (incl. weekenden en feestdagen), met vaste openingstijden gedefinieerd in `utils.R`. |
| Buiten openingstijd | Buiten openingstijden vinden geen patiëntgerelateerde events plaats. |
| Dagafhandeling | Patiënten doorlopen hun behandelroute in principe op de dag van aankomst. |
| Doorschuiven events | Niet-afgeronde events vóór sluitingstijd (21:00) schuiven door naar de eerstvolgende openingsdag om 09:00. |
| Aantal patiënten | Het totaal aantal patiënten is begrensd en geconfigureerd in `utils.R`. |
| Aankomstverdeling | Aankomstdatum en aankomsttijd van patiënten worden volgens configureerbare verdelingen gegenereerd. |
| Kamercapaciteit | Het aantal kamers en de verdeling naar `kamerType` zijn vastgelegd in `utils.R` en constant gedurende de simulatie. |
| Kameridentiteit | Elke kamer is uniek geïdentificeerd via `kamerId`; meerdere kamers per `kamerType` zijn toegestaan. |
| Wachtrijen | Voor receptie-, diagnose- en behandelkamers bestaan wachtrijen bij onbeschikbaarheid. |
| Queue discipline | Wachtrijen werken volgens FIFO (first in, first out). |
| Behandeltijden | Behandel-, diagnose- en receptieduur zijn per `kamerType` gedefinieerd in `utils.R`. |
| Scenarios | Het scenario per patiënt (bv. `happyFlow`, `foutieveDiagnose`, `kamerOnbeschikbaarheid`) wordt bepaald via configuratie. |
| Foutieve diagnose | Een patiënt kan maximaal één keer een foutieve diagnose krijgen. |
| Kameronbeschikbaarheid | Onbeschikbaarheid (mankement, pauze, ontslag) treedt op kamerId-niveau. |

---

### Non-functionele eisen (implementatie & code)

| Categorie | Eis |
|----------|-----|
| Naamgeving | camelCase voor tabellen, kolommen, functies en objecten. |
| Leesbaarheid | Namen zijn expliciet en semantisch duidelijk. |
| Documentatie | Code is voorzien van functionele en verklarende comments. |
| Technische stack | Tidyverse is het uitgangspunt; afwijkingen zijn toegestaan indien functioneel beter. |
| Centrale configuratie | `./data/generateScripts/utils.R` is de enige bron voor simulatieconfiguratie. |
| Config-inhoud | `utils.R` bevat scenarios, datum- en tijdsbereiken, kamer-, aandoening-, event- en patiëntdimensies. |
| Event-identiteit | De generator produceert unieke, oplopende `eventId`s per patiënt. |

---

## 📖 Validatie-eisen

| Domein | Check |
|--------|-------|
| Tijd | Alle events vallen binnen geldende openingstijden. |
| Capaciteit | Geen overlap in kamergebruik per `kamerId`. |
| Proces | Correcte event-volgorde per patiënt en per scenario. |
| Verdeling | Scenarioverdeling komt overeen met configuratie. |
| Volumes | Totaal aantal patiënten komt overeen met ingestelde limieten. |

---

## {simmer} Implementatie

### Achtergrond
![](./png/simmer-logo.png){width=300px}
Voor documentatie check hier de simmer [website](https://r-simmer.org). 

### {simmer} script
data/generateScripts/simmer/simmerImplementatie.R

### Feature branch - simmerImplementation

| stap | omschrijving | status |
|------|--------------|--------|
| stap 1 | minimale werking in simmer + check op metrieken voor wachttijden + benutting. | ✅ |
| stap 2 | trajectory aanpassen aan bestaande kamers. | 🕘 |
| stap 3 | arrival tijden tweaken om stochastiche aankomsttijden te kunnen behalen + omzetten naar datumTijden. | 🕘 |
| stap 4 | koppeling patientenStamTabel aan arrivals maken - apriori ziektebeeld naar behandelpad. | 🕘 |
| stap 5 | opnieuw check op metrieken berekenen - kan ik ook per aandoening, kamerType en kamerId berekeningen maken. | 🕘 |
| stap 6 | arrivals en trajectories rekening houden met openingstijden van ziekenhuis?. | 🕘 |
| stap 7 | machine breakdown inbouwen - branch() in trajectory. | 🕘 |
| stap 8 | onbeschikbaarheid kamer door pauzes/vacatures?. | 🕘 |
| stap 9 | volgende check op metrieken - nog steeds wachttijden en benutting mogelijk? Heb ik ook tijden van onbeschikbaarheid en kan ik breakdown maken? | 🕘 |
| stap 10 | configurabele simulatieparameters maken, zodat ik simulatie beter kan tweaken | 🕘 |