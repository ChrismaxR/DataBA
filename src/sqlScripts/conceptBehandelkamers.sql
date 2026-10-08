select * from fct_behandelkamer fb
left join dim_behandelkamer b on fb.behandelkamerId = b.id