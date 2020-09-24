# postgres-fire

The idea of this project is to walk all the way through a somewhat normal data science workflow. The end goals for the data science exercise are:

1. Create a logistics model predicting fire probably given weather variables
2. Write a stored procedure that uses the model to predict prob. of a fire given the input weather

We are using the calfire and calweather demo data from the crunchydata/crunchy-

Steps
1. Download the data, create the db, add the postgis extension, & import the pg_dump file. FILE = 1-createload.sh
2. Restrict the fire data only to the N. California region since our Weather data is only from the Morgan Hill Area. Put it in a new table ncal_fire FILE = 2-norcal.sql
3. Pull all the weather corresponding to fire days. Remove 10% of the fires and put in training data and randomly sample weather days without replacement.  Total n of non-fire weather =  1.5x the number of fires. We pull this out first because we will use the withheld data to test the triggers and such
4. Center and Standardize the weather variables. Store it in the same table as new columns - with a cs_ prefix on the name. This could also be done with a view but we don't want to execute that query every time we do other analysis
5. TODO Build the model - probably do this in R or Python and then make it into a procedure
    * Save a graph into the DB - the table for graphs should be
    id| date| picture
    * Save the model output to a table as well
    id| data | interecept| parameter1|...
6. TODO have a function that, givens some predicted weather, return the probability of fire. THe parameters for prediction should be read from the model table with most recent run of the output.
7. REACH TODO - write an update trigger that calculates updates whenever new weather data is added 
    

