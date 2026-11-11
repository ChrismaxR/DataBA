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