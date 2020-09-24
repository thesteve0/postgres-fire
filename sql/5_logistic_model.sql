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
                                               "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                               "from final.analysis"))

        ###############################
        # This model is better behaved but we should compare them for prediction

        logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

        # I am going to return the binary representation
        # serial_results <- serialize(logmodel_solar, NULL)

        dbDisconnect(con)
        dbUnloadDriver(pg)
        return(logmodel_solar)
$$ LANGUAGE 'plr';

select pg_typeof(plr_get_raw(final.logistic_model()));

insert into final.logistic_models (name, model) values ('hello', final.logistic_model())



