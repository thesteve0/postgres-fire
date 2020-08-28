-- output is going to be a new weather table with a column named hadfire with 1 for yes and 0 for no


-- First table will be just the join of fires with their weather info into 1 big table that combines all th fields. This will be useful if we ever want to explore anything about the weather with fire size, shape, or other geography variables

-- There are numerous days with multiple fires, I think we will need to group by alarm date and do a CTE
select

-- Next table is weather variables with 1 and 0s, no fire information

-- Then we create two derivative tables - fire-training and fire-test with 90% and 10% of the data above respectively