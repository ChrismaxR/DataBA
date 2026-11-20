select * from dim_aandoening;

select * from dim_behandelkamer;

select * from dim_patient;

select * from fct_behandelkamer limit 100;

select * from fct_gebeurtenis;


  select "aandoeningNaam",
          "behandelkamerNaam",
          "behandelkamerType",
           behandeltijd,
           wachttijd
    from fct_gebeurtenis fg
    left join dim_patient p on fg.patientId = p.id
    left join dim_aandoening a on p.aandoeningId = a.id
    left join dim_behandelkamer b on fg.behandelkamerId = b.id

    ;

select  behandelkamerId, 
          tijdstip, 
          capaciteit, 
          patientenInBehandeling, 
          patientenInWachtrij,
          (epoch_ms(lead(tijdstip) over (partition by simulatieRun, behandelkamerId order by tijdstip, id))
          - epoch_ms(tijdstip)) / 60000.0                                       as duurMinuten
  from fct_behandelkamer

  ;

  select aandoeningNaam, 
  count(*) as aantal
  from dim_patient
  left join dim_aandoening ON (dim_aandoening.id = dim_patient."aandoeningId")
  group by "aandoeningNaam"
  order by aantal desc
  limit 5

  ;

  select month(fg.startTijdstip) as maandNr,
       ['januari','februari','maart','april','mei','juni','juli', 'augustus','september','oktober','november','december'][month(fg.startTijdstip)] as maand,
       date_trunc('month', fg.startTijdstip) as maand2,
       a.aandoeningNaam,
       count(fg.patientId) as aankomsten
from fct_gebeurtenis fg
  left join dim_patient p on fg.patientId = p.id
  left join dim_aandoening a on p.aandoeningId = a.id
  left join dim_behandelkamer b on fg.behandelkamerId = b.id
  inner join (select aandoeningId, count(*) as aantal
              from dim_patient
              left join dim_aandoening ON (dim_aandoening.id = dim_patient."aandoeningId")
              group by aandoeningId
              order by aantal desc
              limit 5) top5 on a.id = top5.aandoeningId
where b.behandelkamerType = 'Receptie'
group by all
order by maand2, a.aandoeningNaam;

with volume as (
  select r.Diagnose, r.Behandeling, count(*) as patienten
  from dim_patient p
  join AandoeningRoutes r on p.aandoeningId = r.AandoeningId
  group by all
)
select 'Reception' as source, Diagnose as target, sum(patienten) as value
from volume group by all
union all
select Diagnose, Behandeling, sum(patienten)
from volume group by all

;
with volume as (
  select r.Diagnose, r.Behandeling, count(*) as patienten
  from dim_patient p
  join dim_aandoeningRoutes r on p.aandoeningId = r.AandoeningId
  group by all
)
select 'Reception' as source, Diagnose as target, sum(patienten) as value
from volume group by all
union all
select Diagnose, Behandeling, sum(patienten)
from volume group by all

;
with v as (
  select r.Route || ' · ' || r.AandoeningNaam as aandoening,
         r.Diagnose, r.Behandeling, count(p.id) as patienten
  from dim_aandoeningroutes r
  left join dim_patient p on p.aandoeningId = r.AandoeningId
  group by all
)
select aandoening as source, Diagnose as target, patienten as value from v
union all
select Diagnose, Behandeling, sum(patienten) from v group by all