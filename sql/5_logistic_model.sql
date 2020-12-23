-- create the table to hold the images
create table final.logistic_models(
                                id serial primary key,
                                name text,
                                model bytea,
                                created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION final.logistic_model()
    RETURNS bytea as $$
        require( 'RPostgreSQL')

        # https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
        pg = dbDriver("PostgreSQL")
        con = dbConnect(pg, user="postgres", password="password",
                        host="localhost", port=5432, dbname="fire")
        df <- dbGetQuery(con,paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                               "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min",
                                               "from final.analysis"))


        logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

        dbDisconnect(con)
        dbUnloadDriver(pg)
        return(logmodel_solar)
$$ LANGUAGE 'plr';

insert into final.logistic_models (name, model) values ('hello', final.logistic_model());

--CREATE OR REPLACE FUNCTION final.predict_logistic(newdata final.analysis, model bytea, out probability numeric)
CREATE OR REPLACE FUNCTION final.predict_logistic( model bytea, newdata final.test, out probability numeric)
as $$
    probability <- predict(model, data.frame(newdata), type = 'response')

    return(probability)

$$ LANGUAGE 'plr';

-- if I changed the select query in the newdata query so it returned  multiple columns rather than * , postgresql would complain that a subquery can only return 1 column.
-- Now I am not sure why that is the case that a subquery can only return one column, so if anyone wants to enlighten me I would be all ears
-- But now I understand that *::table  casts the result to a record from the table
-- If I had wanted to return multiples columns I would either have to my function signature to take each of the columns OR I could make a composite type that was just the columns I wanted and then put that in the function signature

select final.predict_logistic(newdata :=
    (select f.*::final.test  from final.test as f order by f.date_time limit 1),
    model := (select model as themodel from final.logistic_models as l order by l.created_at desc limit 1)) as fire_probability;

select f.*::final.test  from final.test as f order by f.date_time limit 1
select * from final.logistic_models as l order by l.created_at desc limit 1