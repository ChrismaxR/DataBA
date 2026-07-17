---
title: Index
hide_title: true
hide_header: false
breadcrumb: false
hide_toc: true
---

![Theme Hospital](/hero.png)

# Wachttijden & Capaciteitsbeheer

Dit dashboard is gebouwd op basis van een discrete-event simulatie van een volledig jaar ziekenhuisoperaties in Theme Hospital. De simulatie modelleert de doorloop van patiënten — van aankomst tot ontslag — via 20 behandelkamers en 33 aandoeningen. 

Het doel: inzicht geven in wachttijden en bezettingsgraad, zodat capaciteitsbeslissingen beter onderbouwd kunnen worden.

---

# Kenmerken van dit ziekenhuis


<Grid cols=3>
  <BigValue 
    data={totaal} 
    value=behandelkamers
    title="# Behandelkamers"
  />
  <BigValue 
    data={totaal} 
    value=aandoeningen
    title="# Aandoeningen"
  />
  <BigValue 
    data={totaal} 
    value=patienten
    title="# Patienten"
  />
  <BigValue 
    data={totaal} 
    value=gemiddeldeBehandeltijdMin
    title="Gem. Behandeltijd (minuten)"
  />
  <BigValue 
    data={totaal} 
    value=gemiddeldeWachttijdMin
    title="Gem. Wachttijdn (minuten)"
  />
  <BigValue 
    data={totaal} 
    value=mediaanWachttijdMin
    title="Mediane wachttijd (minuten)"
  />

</Grid>


---
## De Stakeholder

<Grid cols=2>


<div>
Dr. Van Dalen is COO bij Theme Hospital in ThemeVille. Ze is 44 jaar en vervult al een aantal jaren haar rol in het ziekenhuis. Ze voelt zich betrokken bij het welbevinden van patiënten en medewerkers, en heeft als centraal richtpunt een fluïde doorloop van het zorgsysteem: van aankomst tot afronding van de juiste behandeling.<br> <br>  
Haar voornaamste doel is **operationele excellence**. De sleutel daartoe ligt in het effectief managen van wachttijden — in Theme Hospital aangeduid als *Queue Length*.

> *"Waar moet ik volgende maand capaciteit toevoegen of herverdelen om wachttijden onder X te houden?"*

</div>

<img src="/Persona.png" alt="Dr. Van Dalen" style="float: right; width: 230px; margin: 0 0 1rem 2rem;" />


</Grid>

---

Goed wachttijdbeheer is van belang voor:
- de gezondheid en het welbevinden van patiënten
- de operationele excellentie van de organisatie
- de cashflow van het ziekenhuis
- de reputatie van het ziekenhuis

Theme Hospital hanteert een **maandelijkse rapportagecyclus** om de operatie op dit vlak te reviewen.

---

## Afhankelijkheden & onzekerheden

<Grid cols=2>

<div>

**Afhankelijkheden**
- Toeloop van patiënten
- Beschikbaarheid van diagnose- en behandelcapaciteit
- Diagnose- en behandelfouten
- Gelimiteerde capaciteit: het ziekenhuis heeft een eindige capaciteit

</div>

<div>

**Onzekerheden**
- Variatie in voorkomendheid van te behandelen aandoeningen
- Onbeschikbaarheid van apparatuur door slijtage en storingen
- Beschikbaarheid van personeel door verloop

</div>

</Grid>

---

## Informatiebehoefte van Dr. Van Dalen

1. Wat zijn de wachttijden in het ziekenhuis?
2. Wat is de benuttingsgraad van de behandelkamers?
3. Is de verhouding met de zorgcapaciteit in balans?
4. Hoe ontwikkelt de benutting zich door de tijd?
5. Hoe ontwikkelt de capaciteit zich door de tijd?
6. Welke instrumenten zijn er om eventuele problemen te voorkomen?
7. Kan benutting en capaciteit gemodelleerd worden voor forecasts?

---



```sql totaal
select * from totaal

```
