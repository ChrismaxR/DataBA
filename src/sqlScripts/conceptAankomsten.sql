select  month(fg.startTijdstip) as maandNr,
        ['januari','februari','maart','april','mei','juni','juli','augustus','september','oktober','november','december'][month(fg.startTijdstip)] as maand,
        a.aandoeningNaam,
        count(fg.patientId) as aankomsten
from fct_gebeurtenis fg
  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id
where b.behandelkamerType = 'Receptie'
group by all
order by maandNr, a.aandoeningNaam;

;

select fg.patientId, 
date_trunc('month', fg.startTijdstip) as maand2,
date(fg.startTijdstip) as maandNr,
        ['januari','februari','maart','april','mei','juni','juli','augustus','september','oktober','november','december'][month(fg.startTijdstip)] as maand

from fct_gebeurtenis fg
  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id
where b.behandelkamerType = 'Receptie'

;
select a.aandoeningNaam,
       count(fg.patientId) as aankomsten
from fct_gebeurtenis fg
  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id
where b.behandelkamerType = 'Receptie'
group by all
order by aankomsten desc, a.aandoeningNaam

limit 5;

;
select avg(behandeltijd) as gemiddeldeBehandeltijdMin, avg(wachttijd) as gemiddeldeWachttijdMin, median(wachttijd) as mediaanWachttijdMin from fct_gebeurtenis