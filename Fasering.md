# Fasering

Implementatieplan voor de nieuwe opzet van het project: scenario's simuleren als input voor het meerjarig beleidsplan van de COO. Zie [README.md](README.md) voor de context.

**Gekozen scenario's voor 2027:** scenario 3 (grotere en grilligere patiëntenpopulatie) en scenario 4 (arbeidsmarktkrapte).

---

## Fase 1: Fundament herstellen

**Doel:** een werkende pijplijn van simulatie tot dashboard op het huidige sterschema.

- [x] Controleren of het Evidence-dashboard nog bouwt en draait (`npm run sources`, `npm run dev`).
- [x] Bronqueries in `dashboard/sources/hospital/*.sql` omzetten naar het sterschema (`fct_*` / `dim_*`), op basis van de concepten in `src/sqlScripts/concept*.sql`.
- [ ] **Known issue oplossen:** wijzigingen uit `capaciteit_schema` worden binnen een dag overschreven door het dagelijkse werkschema. Richting: `maak_work_schedule()` per dag een eigen capaciteit geven, in plaats van `set_capacity()` te gebruiken. Dit is een voorwaarde voor tijdelijke krapte in scenario 4.

**Klaar als:** het dashboard draait op `hospital.duckdb` en een capaciteitswijziging blijft de geplande periode actief.

---

## Fase 2: Baseline 2026 en boxmodel

**Doel:** een geloofwaardige, gekalibreerde weergave van de huidige operatie.

- [ ] `simOrigin` op 2026-01-01 zetten.
- [ ] Parameters (aankomst, capaciteit, behandelduur) zo afstemmen dat de baseline "goede scores" geeft: een gezonde benutting (indicatief 70–85%) en wachttijden binnen de norm.
- [ ] KPI-definities vastleggen (bezetting, benutting, wachttijd P50/P90, doorlooptijd, % binnen norm). Zie README sectie 8.
- [ ] Boxmodel afleiden uit de baseline-output: stromen Receptie → Diagnose → Behandeling, routekansen per aandoening, benutting per kamer.
- [ ] Boxmodel visualiseren (drawio of mermaid) en opnemen in het dashboard.

**Klaar als:** de baseline stabiel is over meerdere seeds en het boxmodel de huidige operatie uitlegt.

---

## Fase 3: Scenario-infrastructuur

**Doel:** willekeurige scenario's herhaald kunnen doorrekenen zonder code te dupliceren.

- [ ] Scenariodefinitie als lijst met overrides op de baseline-config, zodat `simmerConfig.R` de enige bron van waarheid blijft. De locatie (in de config of in een nieuw bestand) wordt vooraf afgestemd.
- [ ] `simmerImplementatie.R` omzetten naar een functie `run_scenario(scenario, seed)`.
- [ ] Datamodel uitbreiden: `dim_scenario`, en `scenarioId` + `runId` op de fact-tabellen. `databaseUtils.R` daarop aanpassen.
- [ ] Aantal runs en opslag:
  - starten met 30–100 replicaties per scenario (10.000 runs van een jaar is waarschijnlijk te zwaar qua rekentijd en DuckDB-grootte);
  - parallelliseren met `furrr`;
  - per run alleen aggregaten bewaren (dag/maand × kamer); de volledige `fct_gebeurtenis` alleen voor één representatieve run per scenario.

**Klaar als:** de baseline als "scenario 0" via `run_scenario()` draait, met meerdere runs in de database.

---

## Fase 4: Scenario's 2027 uitwerken

### Scenario 3: Grotere en grilligere patiëntenpopulatie

- [ ] Hogere aankomstintensiteit via `aankomst_schema` (bijv. +10% / +20% / +30% als varianten).
- [ ] Meer grilligheid in de toeloop: een aankomstverdeling met meer spreiding dan de exponentiële verdeling (bijv. gamma-verdeelde tussenaankomsttijden of variërende dagintensiteit).
- [ ] Aannames per variant onderbouwen en vastleggen.

### Scenario 4: Arbeidsmarktkrapte

- [ ] **Permanent:** structureel minder capaciteit voor specifieke kamers via `resource_definitie`.
- [ ] **Tijdelijk:** periodes van verminderde capaciteit via `capaciteit_schema` (vereist de fix uit fase 1).
- [ ] Kiezen welke kamers/personeelsgroepen geraakt worden. Het boxmodel uit fase 2 laat zien welke kamers al het dichtst tegen hun grens zitten.

**Klaar als:** beide scenario's met meerdere runs zijn doorgerekend en de resultaten in DuckDB staan.

---

## Fase 5: Dashboard voor de COO

**Doel:** scenario-uitkomsten vertalen naar beleidsinput.

- [ ] Pagina **Huidige operatie**: boxmodel en baseline-KPI's.
- [ ] Pagina **Scenario's**: per KPI baseline naast scenario, met bandbreedtes (P10–P90 of fan charts).
- [ ] Knelpuntkamers per scenario en het moment waarop de wachttijdnorm wordt overschreden.
- [ ] Een samenvatting in beleidstaal: wat betekent dit voor het meerjarig beleidsplan, en welke capaciteit is nodig om binnen de norm te blijven?

---

## Fase 6: Afronding portfolio

- [ ] README-secties 8 (metrics & aannames) en 9 (screenshots) definitief invullen.
- [ ] Legacy-scripts (`simmerAggregate.R`, `simmerStatistics.R`) naar `oud/` verplaatsen.
- [ ] Storytelling-document (Quarto) bijwerken naar de nieuwe opzet.

---

## Later

- Scenario 1: verschuiving in ziekten (welvaarts- en ouderdomsziekten)
- Scenario 2: infectieziekten met meerdere epidemiegolven (afgebakend als epidemie, niet als pandemie)
- Priority queueing, kosten per scenario, capaciteitsoptimalisatie
