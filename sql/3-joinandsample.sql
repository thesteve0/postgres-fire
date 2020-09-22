-- output is going to be a new weather table with a column named hadfire with 1 for yes and 0 for no


-- First table will be just the join of fires with their weather info into 1 big table that combines all th fields. This will be useful if we ever want to explore anything about the weather with fire size, shape, or other geography variables

-- There are numerous days with multiple fires, I think we will need to group by alarm date and do a CTE
with grouped_fire as (
    select alarm_date, count(*) as numfires, string_agg(fire_name, ', ') as names, st_collect(geom)::geometry(geometrycollection, 3310) as geom from ncalfire group by alarm_date
) select w.*, grouped_fire.*, 1 as hasfire into fire_weather from weather w, grouped_fire where grouped_fire.alarm_date = w.date_time::date;

-- turn the geometrycollection back into multipolygons
alter table fire_weather alter column geom type geometry(multipolygon,3310) using st_collectionextract(geom, 3);

-- Create a data set without fires. Need to create the extra columns so we can use Union
with non_fire_weather as (
    select weather.*
    from weather where id not in (select id from fire_weather)
) select non_fire_weather.*, null::date as alarm_date, 0::bigint as numfires, null::text as names, null::geometry(MultiPolygon,3310) as geom, 0 as hasfire into non_fire_weather from non_fire_weather;

-- Next table is all weather variables with 1 and 0s
select * into alldata from non_fire_weather UNION select * from fire_weather;


 ---sampling an equal number of non-fire days
with count_fire as (
    select count(*) as thecount from fire_weather
)
select a.* into preanalysisdata from count_fire cross join lateral (select * from non_fire_weather tablesample system_rows(count_fire.thecount)) as a;

--create a table that we can now sample from
select * into analysisdata from preanalysisdata UNION select * from fire_weather;

-- create a schema to hold the final data
create schema final;
-- Then we create two derivative tables - fire-training and fire-test with 90% and 10% of the data above respectively
select * into final.analysis from analysisdata tablesample system_rows(2525);
select * into final.verification  from analysisdata except select * from final.analysis;

alter table final.analysis add primary key (id);
