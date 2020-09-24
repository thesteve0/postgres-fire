# Title     : TODO
# Objective : TODO
# Created by: steve
# Created on: 9/17/2020
# install.packages("car", dependencies=TRUE) for standard R distro


require( 'RPostgreSQL')

# https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user="postgres", password="password",
                host="localhost", port=5432, dbname="fire")
df <- dbGetQuery(con,statement = paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                       "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                       "from final.analysis"))

###############################
# This model is better behaved but we should compare them for prediction

logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

# I am going to return the binary representation
## we get back raw
serial_results <- serialize(logmodel_solar, NULL)


# Now read the model back out of the table and see if we get the summary to work
## We get back a list
binary_model <- dbGetQuery(con,statement = "select model from final.logistic_models order by created_at desc limit 1")

### Ok so the DB stores the right bytes. I have confirmed that the 1st, 99941, 99942 octets are the same on
### serial_results and model in the final.logistic models table.
##  Things go wrong when I try to get the bytes back in R using a sql query.
## Nothings seems to change, I always get a list back in R instead of a raw. The contents of the list don't match the
## octets in the bytea in Postgresql. Somewhere in this call the binary is getting converted to something that I
## don't know how to convert back. I have tried all sorts of various combinations of charToRaw as.raw.
## I feel like it might have to do with the way bytea is converted to Object on the R side.

attempt <- charToRaw((paste0('0x', binary_model)))
attempt <- charToRaw(binary_model)
typeof(binary_model)
typeof(serial_results)
unserialize(attempt)
as.hexmode(binary_model)

dbDisconnect(con)
dbUnloadDriver(pg)
