--  Center and Standardize the weather variables.
https://www.postgresql.org/docs/current/plpgsql-statements.html#PLPGSQL-STATEMENTS-EXECUTING-DYN
https://www.postgresql.org/docs/current/functions-string.html#FUNCTIONS-STRING-FORMAT
--  Store it in the same table as new columns - with a cs_ prefix on the name
with summary as (
    select avg(precip), stddev(precip)
    from final.analysis
)
select precip, (precip - avg)/stddev from final.analysis, summary;

create or replace function final.initial_center_standardize(table_name text, prefix text, column_names text[])
    returns text as
$$
DECLARE
    col text;
    new_col_name text;
BEGIN
    -- loop through column names
    foreach col in ARRAY column_names
        LOOP
            -- Create the column
            new_col_name := prefix || col;
            -- EXECUTE starts the statement because we don't want to cache the plan since each iteration of the loop is new SQL
            EXECUTE format('alter table %I add column %I numeric', table_name, new_col_name);
            raise info 'After adding the column';


            -- calculate the data
            EXECUTE 'insert into $3 ($2) with summary as ( select avg($1), stddev($1) from $3)' ||
                    'select  ($1 - avg)/stddev from $3, summary;'
                USING col, new_col_name, table_name;
        END LOOP;
    return 'done';
END;
$$ LANGUAGE plpgsql;

select final.initial_center_standardize('final'::text, 'test'::text, 'cs_'::text, array ['precip', 'eto', 'solar', 'rh_max']::text[]);

create table final.test as select * from final.analysis;