with toestand as (
  -- elke snapshot geldt tot de volgende snapshot van dezelfde kamer
  select behandelkamerId, tijdstip, capaciteit, patientenInBehandeling, patientenInWachtrij,
         (epoch_ms(lead(tijdstip) over (partition by simulatieRun, behandelkamerId order by tijdstip, id))
          - epoch_ms(tijdstip)) / 60000.0 as duurMinuten
  from fct_behandelkamer
)
select  date_trunc('month', t.tijdstip)::date                        as maand,
        b.behandelkamerNaam,
        b.behandelkamerType,
        sum(t.capaciteit * t.duurMinuten) / 60                        as beschikbareUren,
        sum(t.patientenInBehandeling * t.duurMinuten) / 60            as bezetteUren,
        sum(t.patientenInBehandeling * t.duurMinuten)
          / nullif(sum(t.capaciteit * t.duurMinuten), 0)              as benuttingsgraad,
        -- gemiddelden alleen over openingstijd (capaciteit > 0)
        sum(t.patientenInBehandeling * t.duurMinuten) filter (where t.capaciteit > 0)
          / nullif(sum(t.duurMinuten) filter (where t.capaciteit > 0), 0) as gemBezetteKamers,
        sum(t.patientenInWachtrij * t.duurMinuten) filter (where t.capaciteit > 0)
          / nullif(sum(t.duurMinuten) filter (where t.capaciteit > 0), 0) as gemWachtrij,
        max(t.patientenInWachtrij)                                    as maxWachtrij,
        max(t.capaciteit)                                             as maxCapaciteit
from toestand t
  join dim_behandelkamer b on t.behandelkamerId = b.id
where t.duurMinuten is not null
group by all
order by maand, b.behandelkamerNaam
