#!/bin/bash
PGPASSWORD="password"

#Download the data here
wget https://github.com/CrunchyData/crunchy-demo-data/releases/download/V0.6.5.1/crunchy-demo-fire.dump.sql.gz

###### Ucomment for cloud or new database
#createdb -h 52.167.136.70 -U postgres -p 5432 fire

# Create the extension here
###### Ucomment for cloud or new database
#psql -h 52.167.136.70 -U postgres -p 5432 -c 'create extension postgis' fire
#psql -h 52.167.136.70 -U postgres -p 5432 -c 'create extension  tsm_system_rows' fire


# load the data
gunzip -c crunchy-demo-fire.dump.sql.gz | psql -h localhost -U postgres -p 5432 fire
psql -h localhost -U postgres -p 5432 -c 'vacuum freeze analyze;' fire