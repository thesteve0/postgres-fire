# Title     : TODO
# Objective : TODO
# Created by: steve
# Created on: 9/17/2020
# install.packages("car", dependencies=TRUE) for standard R distro


library( 'RPostgreSQL')
library('car')


# https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user="postgres", password="password",
                host="localhost", port=5432, dbname="fire")
df <- dbGetQuery(con,statement = paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                       "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                       "from final.analysis"))

logmodel <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip, data=df, family = binomial("logit"))

summary(logmodel)

vif(logmodel)

plot(logmodel)
###############################
# This model is better behaved but we should compare them for prediction

logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

summary(logmodel_solar)

vif(logmodel_solar)

plot(logmodel_solar)
