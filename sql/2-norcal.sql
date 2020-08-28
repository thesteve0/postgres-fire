-- This file samples the fires to only those in wholely within Northern California into a new table. It then creates a index on the spatial column.
-- we chose within rather than intersect because it is just cleaner and there is still 2626 fire polygons still left
select fire19.* into ncalfire from fire19, fire19_region where st_covers(fire19.geom, fire19_region.geom) and fire19_region.region = 'Northern';

create index ncalfire_geom_idx on ncalfire using gist(geom);