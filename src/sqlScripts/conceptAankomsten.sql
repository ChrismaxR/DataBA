with fg as (
  select * replace (
    timestamp '2025-01-01 09:00:00' + to_seconds(startTijdstip * 60) as startTijdstip,
    timestamp '2025-01-01 09:00:00' + to_seconds(eindTijdstip * 60) as eindTijdstip
  )
  from fct_gebeurtenis
  
  --limit 100000

)

select  --behandelkamerType,
        month(fg.startTijdstip) as maand, 
        a.aandoeningNaam,
        count(patientId) as aankomsten
from fg

  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id

  where b.behandelkamerType = 'Receptie'

group by
  --behandelkamerType,
  month(fg.startTijdstip),
  a.aandoeningNaam

order by
  month(fg.startTijdstip),
  a.aandoeningNaam