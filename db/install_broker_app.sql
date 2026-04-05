SET FEEDBACK ON
SET ECHO ON

PROMPT '--- Starting Broker App Installation ---'

@db/setup/02_database_main.sql;        -- Core Tables
@db/setup/03_constraints.sql;          -- PK/FK Constraints
@db/setup/04_indexing.sql;             -- Indexes
@db/setup/05_stored_procedures.sql;    -- Trading Logic
@db/staging/mock_data.sql;             -- Initial Seed Data

PROMPT '--- Broker App Installation Completed! ---'
