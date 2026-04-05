SET FEEDBACK ON
SET ECHO ON

PROMPT '--- Starting Data Warehouse Installation ---'

PROMPT '1. Creating Functions...'
@db/setup/06_functions.sql

PROMPT '2. Creating Staging Tables...'
@db/staging/stg_tables.sql

PROMPT '3. Creating Dimension Tables...'
@db/dimensions/dim_tables.sql

PROMPT '4. Creating Fact Tables...'
@db/facts/fact_tables.sql

PROMPT '5. Creating ETL Procedures...'
@db/setup/07_etl_procedures.sql

PROMPT '6. Populating Date Dimension...'
@db/setup/09_populate_date.sql

PROMPT '7. Deploying Mart Views...'
@db/marts/mart_views.sql

PROMPT '--- Data Warehouse Installation Completed! ---'
PROMPT 'Ready to run: EXEC dbt_run;'
