with benut as (
  select tijdstip, 
       patientenInBehandeling, 
       capaciteit,
       patientenInBehandeling/capaciteit as benutting

from fct_behandelkamer
where capaciteit != 0

)

select benutting, count(benutting) from benut group by benutting, order by benutting

;

select tijdstip, patientenInWachtrij
from fct_behandelkamer
order by tijdstip