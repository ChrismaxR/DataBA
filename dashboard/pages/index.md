---
title: Index
hide_title: true
hide_header: false
breadcrumb: false
hide_toc: true
---

![Theme Hospital](/hero.png)

# Case: Wachttijden & Capaciteitsbeheer in een fictief Ziekenhuis

Dit is een casebeschrijving van hoe ik als Business Analist binnenn een data/BI team een project zou uitvoeren. 

Deze case betreft een zogenaamde 'Discrete Event Simulatie' (DES) van een volledig jaar ziekenhuisoperaties in het fictieve ziekenhuis Theme Hospital. De simulatie modelleert de behandeling van patiënten — van aankomst tot ontslag — met in totaal 33 aandoeningen in 19 verschillende type behandelkamers. De set is gebaseerd op een ziekenhuissimulatiespel (scrabble woord!) uit de jaren negentig, wat ik met veel plezier helemaal kapot heb gespeeld.  

---
## De Stakeholder (Stakeholder/user analysis)

<Grid cols=2>


<div>
Dr. Van Dalen is COO bij Theme Hospital in ThemeVille. Ze is 44 jaar en vervult al een aantal jaren haar rol in het ziekenhuis. Ze voelt zich betrokken bij het welbevinden van patiënten en medewerkers, en heeft als centraal richtpunt een fluïde doorloop van het zorgsysteem: van aankomst tot afronding van de juiste behandeling.<br> <br>  
Haar voornaamste doel is operationele excellence. De sleutel daartoe ligt in het effectief benutten van zorgcapaciteit en het managen van wachttijden.

> *"Waar moet ik volgende maand capaciteit toevoegen of herverdelen om wachttijden onder X te houden?"*

</div>

<img src="/Persona.png" alt="Dr. Van Dalen" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />


</Grid>

Deze vraag juist beantwoorden heeft een positief effect op:

- de gezondheid en het welbevinden van patiënten
- de optimale benutting van personeel en middelen
- de reputatie & financieel resultaat van het ziekenhuis

---

## Informatiebehoefte van Dr. Van Dalen (Requirements engineering)

1. Wat zijn de wachttijden in het ziekenhuis?
2. Wat is de benuttingsgraad van de behandelkamers?
3. Is de verhouding tussen zorgcapaciteit en benutting in balans?
4. Hoe ontwikkelt de benutting zich door de tijd?
5. Hoe ontwikkelt de capaciteit zich door de tijd?
6. Welke instrumenten zijn er om eventuele problemen te voorkomen?
7. Kan benutting en capaciteit gemodelleerd worden voor forecasts?

Theme Hospital hanteert een **maandelijkse rapportagecyclus** om de operatie te reviewen.

---

## Modelleren van Theme Hospital (Modelling Business Process)

### Procesbeschrijving Ziekenhuis 
Het pad dat een patiënt generiek bewandelt is als volgt:

<img src="/model.png" alt="Diagram"/>

### Factoren die werking van het proces beïnvloeden:

<Grid cols=2>

<div>

#### Afhankelijkheden
- Toeloop van patiënten
- Beschikbaarheid van diagnose- en behandelcapaciteit
- Diagnose- en behandelfouten
- Gelimiteerde capaciteit: het ziekenhuis heeft een eindige capaciteit
- Behandelprotocollen die diagnose- en behandeltijd dicteren.

</div>

<div>

#### Onzekerheden
- Variatie in voorkomendheid van te behandelen aandoeningen
- Onbeschikbaarheid van apparatuur door slijtage en storingen
- Beschikbaarheid van personeel door verloop en onbeschikbaarheid

</div>

</Grid>

---

## Opzetten van een oplossing (Defining the solution/prototyping)

1. Visualiseren van belangrijkste indicatoren middels een maandelijks dashboard
2. Scenario's en planvorming aan de hand van bepaalde grenswaarden

---





``` sql totaal
```