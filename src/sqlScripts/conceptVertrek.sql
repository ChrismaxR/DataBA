select date_trunc('month', fg."eindTijdstip") as maand,
       'vertrek' as direction,
       count(fg.patientId) * -1 as count
    from fct_gebeurtenis fg
    left join dim_patient p on fg.patientId = p.id
    left join dim_aandoening a on p.aandoeningId = a.id
    left join dim_behandelkamer b on fg.behandelkamerId = b.id
    where b.behandelkamerType in ('Kliniek', 'Polikliniek')
    group by all

union all 

  select date_trunc('month', fg.startTijdstip) as maand,
         'aankomst' as direction,
         count(fg.patientId) as count
    from fct_gebeurtenis fg
    left join dim_patient p on fg.patientId = p.id
    left join dim_aandoening a on p.aandoeningId = a.id
    left join dim_behandelkamer b on fg.behandelkamerId = b.id
    where b.behandelkamerType = 'Receptie'
    group by all

