-- create the table to hold the images
create table plots(
  id serial primary key,
  name text,
  image bytea
);


CREATE OR REPLACE FUNCTION image_me()
    RETURNS bytea as $$
    require( 'RPostgreSQL')

# https://cran.r-project.org/web/packages/RPostgreSQL/RPostgreSQL.pdf
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user="postgres", password="password",
                host="localhost", port=5432, dbname="fire")

query_statement <- paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                       "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                       "from final.analysis")
df <- dbGetQuery(con, query_statement)

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


## return the bytes
 return(binary_png)
$$ LANGUAGE 'plr';

insert into plots(name, image)  select 'mypicture', get_image.* from plr_get_raw(image_me()) as get_image;