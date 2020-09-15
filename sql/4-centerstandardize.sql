--  Center and Standardize the weather variables.
https://www.postgresql.org/docs/current/plpgsql-statements.html#PLPGSQL-STATEMENTS-EXECUTING-DYN
https://www.postgresql.org/docs/current/functions-string.html#FUNCTIONS-STRING-FORMAT
--  Store it in the same table as new columns - with a cs_ prefix on the name
with summary as (
    select avg(precip), stddev(precip)
    from final.analysis
)
select precip, (precip - avg)/stddev from final.analysis, summary;

create or replace function final.initial_center_standardize(schema_name text, table_name text, prefix text, column_names text[], pkey text)
    returns text as
$$
DECLARE
    col text;
    new_col_name text;
    debug_string text;
BEGIN
    -- loop through column names
    foreach col in ARRAY column_names
        LOOP
            -- Create the column
            new_col_name := prefix || col;
            -- EXECUTE starts the statement because we don't want to cache the plan since each iteration of the loop is new SQL
            EXECUTE format('alter table %I.%I add column %I numeric', schema_name, table_name, new_col_name);
            raise info 'After adding the column';

            debug_string := FORMAT('with summary as ( select avg(%1$I) as avg, stddev(%1$I) as stddev from %3$I.%4$I), ' ||
                                   'final_select as (%5$I, (%1$I - avg)/stddev as centered from %3$I.%4$I left join summary on true) ' ||
                                   'update %3$I.%4$I  set %2$I = final_select.centered from final_select where final_select.%5$I =  %3$I.%4$I.%5$I ', col, new_col_name, schema_name, table_name, pkey)::text;
            raise info ' Here is the string:: %', debug_string;
            -- calculate the data
            EXECUTE FORMAT('with summary as ( select avg(%1$I) as avg, stddev(%1$I) as stddev from %3$I.%4$I), ' ||
                           'final_select as (select %5$I, (%1$I - avg)/stddev as centered from %3$I.%4$I left join summary on true) ' ||
                           'update %3$I.%4$I  set %2$I = final_select.centered from final_select where final_select.%5$I =  %3$I.%4$I.%5$I ', col, new_col_name, schema_name, table_name, pkey);
        END LOOP;
    return 'done';
END
$$ LANGUAGE plpgsql;

select final.initial_center_standardize('final'::text, 'test'::text, 'cs_'::text, array ['precip', 'eto', 'solar', 'rh_max']::text[], 'id'::text);

create table final.test as select * from final.analysis;