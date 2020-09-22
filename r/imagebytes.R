# Title     : TODO
# Objective : TODO
# Created by: steve
# Created on: 9/21/2020

require( 'RPostgreSQL')

# https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user="postgres", password="password",
                host="localhost", port=5432, dbname="fire")
df <- dbGetQuery(con,statement = paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                       "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                       "from final.analysis"))

logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

# Write plot to file, get bytes, put in DB, and then delete it
# Set up the PNG and write to disk
thefile <- "deleteme.png"
png(filename = thefile)
plot(logmodel_solar)
dev.off()

## read it back from disc to a binary
binary_png <- paste(readBin(thefile, what = "raw", n = 1e8))

## delete the image
file.remove(thefile)

dbDisconnect(con)
dbUnloadDriver(pg)

## return the bytes
 binary_png

