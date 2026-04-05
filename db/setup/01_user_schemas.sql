-- Section 1: Application Source System User
CREATE USER broker_app IDENTIFIED BY "AppPassword123#";
GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO broker_app;
ALTER USER broker_app QUOTA UNLIMITED ON USERS;

-- Section 2: Data Warehouse User
CREATE USER trading_dwh IDENTIFIED BY "DwhPassword123#";
GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO trading_dwh;
ALTER USER trading_dwh QUOTA UNLIMITED ON USERS;

-- Section 3: Cross-Schema Permissions
GRANT SELECT ANY TABLE TO trading_dwh;

PROMPT 'Application and DWH Users Created Successfully!';
