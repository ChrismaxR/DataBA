select date(fb.tijdstip) as datum,
       * 
  from fct_behandelkamer fb
left join dim_behandelkamer b on fb.behandelkamerId = b.id

where datum = date('2025-01-01')
  and "behandelkamerId" = 1