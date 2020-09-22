# Title     : TODO
# Objective : TODO
# Created by: steve
# Created on: 9/16/2020

library( 'RPostgreSQL')
library('lattice')

# https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user="postgres", password="password",
                host="localhost", port=5432, dbname="fire")
df <- dbGetQuery(con,statement = paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                  "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min",
                   "from final.analysis"))

# https://www.statmethods.net/advgraphs/trellis.html
 matrix_plot <- splom(df)

# Now save to binary
# https://www.r-bloggers.com/save-r-plot-as-a-blob/