-- output is going to be a new weather table with a column named hadfire with 1 for yes and 0 for no


-- First table will be just the join of fires with their weather info into 1 big table that combines all th fields. This will be useful if we ever want to explore anything about the weather with fire size, shape, or other geography variables

-- There are numerous days with multiple fires, I think we will need to group by alarm date and do a CTE
with grouped_fire as (
    select alarm_date, count(*) as numfires, string_agg(fire_name, ', ') as names, st_collect(geom)::geometry(geometrycollection, 3310) as geom from ncalfire group by alarm_date
) select w.*, grouped_fire.*, 1 as hasfire into fire_weather from weather w, grouped_fire where grouped_fire.alarm_date = w.date_time::date;

-- turn the geometrycollection back into multipolygons
alter table fire_weather alter column geom type geometry(multipolygon,3310) using st_collectionextract(geom, 3);

-- Now we sample the same number of weather days that did not have fire
with non_fire_weather as (
    select count(weather.*)
    from weather where id not in (select id from fire_weather)
) TODO FINISH THIS STATMENT TO SAMPLE THE RIGHT NUMBER OF RECORDS;

-- Next table is weather variables with 1 and 0s, no fire information

-- Then we create two derivative tables - fire-training and fire-test with 90% and 10% of the data above respectively