---
title: Index
hide_title: true
hide_header: false
breadcrumb: false
hide_toc: true
---

![Theme Hospital](/hero.png)

# Case: Scenario's voor het meerjarig beleidsplan van een fictief ziekenhuis

Dit is een casebeschrijving van hoe ik als Business Analist binnen een data/BI-team een project zou aanpakken.

De case draait om Theme Hospital, een fictief ziekenhuis gebaseerd op een ziekenhuissimulatiespel uit de jaren negentig dat ik met veel plezier helemaal kapot heb gespeeld. Patiënten komen binnen met één van 33 aandoeningen en doorlopen een vast pad langs de receptie, een diagnosekamer en een behandelkamer, verdeeld over 19 typen kamers.

Met een zogenaamde *Discrete Event Simulatie* (DES) wordt eerst een volledig jaar van de huidige operatie nagebootst. Daarna rekent hetzelfde model door hoe het ziekenhuis zich houdt als zorgvraag en zorgaanbod in de komende jaren veranderen.

---
## De Stakeholder

<Grid cols=2>


<div>
Dr. Van Dalen is COO bij Theme Hospital in ThemeVille. Ze is 44 jaar en vervult al een aantal jaren haar rol in het ziekenhuis. Ze voelt zich betrokken bij het welbevinden van patiënten en medewerkers, en heeft als centraal richtpunt een fluïde doorloop van het zorgsysteem: van aankomst tot afronding van de juiste behandeling.<br> <br>
Haar standaardrapportage is op orde: ze weet hoe benutting en wachttijden er vandaag voorstaan. Nu schrijft ze een <b>meerjarig beleidsplan</b>, en daarvoor moet ze vooruitkijken.

> *"Welke toekomstige situaties moet ik aankunnen, en wat doen die met benutting en wachttijden, gegeven mijn behandelcapaciteit?"*

</div>

<img src="/Persona.png" alt="Dr. Van Dalen" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />


</Grid>

Een goed onderbouwd antwoord op deze vraag helpt haar om:

- tijdig te investeren in de kamers en het personeel die als eerste een knelpunt worden
- wachttijden ook onder veranderende omstandigheden binnen de norm te houden
- keuzes in het beleidsplan te verantwoorden met cijfers in plaats van onderbuikgevoel

---

## Informatiebehoefte van Dr. Van Dalen

1. Welke operationele scenario's staat het Ziekenhuis te wachten?
2. Wat gebeurt er met de benutting en wachttijden in elk scenario?
3. Welke behandelkamers worden als eerste een knelpunt, en wanneer?
4. Hoeveel extra (of herverdeelde) capaciteit is nodig om wachttijden onder de norm te houden?
5. Hoe groot is de onzekerheid rond gevonden uitkomsten?

---

## Modelleren van de Business

### Procesbeschrijving Ziekenhuis
Het ziekenhuis is dagelijks van 9.00 tot 17.00u geopend. Het pad dat een patiënt generiek bewandelt is als volgt:

<img src="/model.png" alt="Diagram"/>
<br/>

Indien een patiënt niet volledig gedurende een dag behandelt kan worden, dan komt de patiënt de volgende dag terug voor diens resterende behandeling.

### Verdere detailering
Het standaard _operating model_ kan vervolgens per diagnose- en behandelkamer begrepen worden:




<script>
  // Route-boom: kleur van behandelkamers en aandoeningen per behandelingType
  const kleur = { Polikliniek: '#4E79A7', Kliniek: '#E15759' };
  const groep = (rows, key) => [...new Set(rows.map(r => r[key]))]
    .map(naam => [naam, rows.filter(r => r[key] === naam)]);

  $: boom = {
    name: 'Receptie',
    children: groep(routes, 'diagnose').map(([d, dRows]) => ({
      name: d,
      children: groep(dRows, 'behandeling').map(([b, bRows]) => ({
        name: b,
        itemStyle: { color: kleur[bRows[0].behandelingType] },
        children: bRows.map(r => ({ name: r.aandoeningNaam,
                                    itemStyle: { color: kleur[r.behandelingType] } }))
      }))
    }))
  };
</script>


```sql routes
select r.*, k.behandelkamerType as behandelingType
from hospital.dim_aandoeningRoutes r
left join hospital.dim_behandelkamer k on k.id = r.behandelingId
```

<ECharts config={{
  tooltip: { trigger: 'item' },
  series: [{ type: 'tree', data: [boom], initialTreeDepth: -1,
             left: 80, right: 160,  // vaste ruimte in px voor de labels van root en bladeren
             label: { position: 'left' },
             leaves: { label: { position: 'right', width: 150, overflow: 'truncate' } } }]
}} height="750px" />

<br/>
<span style="color: #4E79A7; font-weight: bold">Poliklinische</span> en <span class="text-[#E15759] font-bold">klinische</span> behandelingen zijn aan hun kleur te herkennen.

---

### Factoren die werking van het proces beïnvloeden:

<Grid cols=2>

<div>

#### Afhankelijkheden
- Toeloop van patiënten
- Beschikbaarheid van diagnose- en behandelcapaciteit
- Gelimiteerde capaciteit: het ziekenhuis heeft een eindige capaciteit
- Werktijden: behandelingen die niet binnen de werkdag afkomen, lopen door naar de volgende dag
- Behandelprotocollen die diagnose- en behandeltijd dicteren

</div>

<div>

#### Onzekerheden
- Verschuiving in de mix van aandoeningen
- Epidemische golven van infectieziekten
- Omvang en grilligheid in aanloop van de patiëntenpopulatie
- Beschikbaarheid van personeel door krapte op de arbeidsmarkt

</div>

</Grid>



---

## Scenario's

Dr. Van Dalen heeft al een aantal hoogover scenario's in haar hoofd:

| # | Scenario | Wat verandert er |
|---|----------|------------------|
| 1 | **Verschuiving in ziekten** | Meer welvaarts- en ouderdomsziekten, en daardoor een andere mix van aandoeningen en routes |
| 2 | **Infectieziekten** | Epidemische golven van één of meer infectieziekten (geen pandemieën) |
| 3 | **Grotere en grilligere patiëntenpopulatie** | Een hogere en minder voorspelbare toeloop |
| 4 | **Arbeidsmarktkrapte** | Een permanent of tijdelijk tekort aan specifiek zorgpersoneel, en dus minder beschikbare kamers |


---
