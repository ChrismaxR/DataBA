-- Test hoe ik behandel- en wachttijden bij elkaar kan queryen

with fg as (
  select * replace (
    timestamp '2025-01-01 09:00:00' + to_seconds(startTijdstip * 60) as startTijdstip,
    timestamp '2025-01-01 09:00:00' + to_seconds(eindTijdstip * 60) as eindTijdstip
  )
  from fct_gebeurtenis
  --limit 100000

)

select  b.behandelkamerType,
        b.behandelkamerNaam,
        a.aandoeningNaam,
        month(fg.startTijdstip) as maand,
        avg(wachttijd) as gemiddeldeWachttijd, 
        avg(behandeltijd) as gemiddeldeBehandeltijd,
        count(fg.patientId) as aantalPatienten
  from fg
  
  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id

group by
b.behandelkamerType,
b.behandelkamerNaam,
a.aandoeningNaam, 
month(fg.startTijdstip)

order by 
month(fg.startTijdstip),
avg(wachttijd)