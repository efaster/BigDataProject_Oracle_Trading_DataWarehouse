-- 1. กลุ่มข้อมูลผู้ใช้งาน (สำหรับรายงาน 2)
CREATE TABLE dw_bronze.stg_users (
    user_id NUMBER,
    username VARCHAR2(50),
    email VARCHAR2(100),
    two_factor_enabled NUMBER(1),
    status VARCHAR2(20),
    created_at TIMESTAMP,
    -- Technical Columns for SCD Type 2
    stg_valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stg_valid_to TIMESTAMP DEFAULT TO_TIMESTAMP('9999-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS'),
    stg_is_current NUMBER(1) DEFAULT 1,
    stg_extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. กลุ่มบัญชีและพอร์ต (สำหรับรายงาน 1 และ 2)
CREATE TABLE dw_bronze.stg_accounts AS SELECT account_id, user_id, account_type, status, created_at FROM broker_app.Accounts WHERE 1=0;
ALTER TABLE dw_bronze.stg_accounts ADD (stg_valid_from TIMESTAMP, stg_valid_to TIMESTAMP, stg_is_current NUMBER(1), stg_extraction_date TIMESTAMP);

CREATE TABLE dw_bronze.stg_portfolio AS SELECT portfolio_id, account_id, total_equity, cash_balance, updated_at FROM broker_app.Portfolio WHERE 1=0;
ALTER TABLE dw_bronze.stg_portfolio ADD (stg_valid_from TIMESTAMP, stg_valid_to TIMESTAMP, stg_is_current NUMBER(1), stg_extraction_date TIMESTAMP);

-- 3. กลุ่มข้อมูลการถือครองและสินทรัพย์ (สำหรับรายงาน 1)
CREATE TABLE dw_bronze.stg_holdings AS SELECT holding_id, account_id, asset_id, quantity, available_qty FROM broker_app.Holdings WHERE 1=0;
ALTER TABLE dw_bronze.stg_holdings ADD (stg_valid_from TIMESTAMP, stg_valid_to TIMESTAMP, stg_is_current NUMBER(1), stg_extraction_date TIMESTAMP);

CREATE TABLE dw_bronze.stg_assets AS SELECT asset_id, symbol, name, type FROM broker_app.Assets WHERE 1=0;
ALTER TABLE dw_bronze.stg_assets ADD (stg_valid_from TIMESTAMP, stg_valid_to TIMESTAMP, stg_is_current NUMBER(1), stg_extraction_date TIMESTAMP);

-- 4. กลุ่มข้อมูลการเทรด (สำหรับรายงาน 1 และ 2)
CREATE TABLE dw_bronze.stg_trades AS SELECT * FROM broker_app.Trades WHERE 1=0;
ALTER TABLE dw_bronze.stg_trades ADD (stg_extraction_date TIMESTAMP);

CREATE TABLE dw_bronze.stg_trading_pairs AS SELECT * FROM broker_app.Trading_Pairs WHERE 1=0;
ALTER TABLE dw_bronze.stg_trading_pairs ADD (stg_extraction_date TIMESTAMP);

-- 5. กลุ่มข้อมูลคำสั่งซื้อ/ขาย 
CREATE TABLE dw_bronze.stg_buy_orders AS SELECT * FROM broker_app.Buy_Orders WHERE 1=0;
ALTER TABLE dw_bronze.stg_buy_orders ADD (stg_extraction_date TIMESTAMP);

CREATE TABLE dw_bronze.stg_sell_orders AS SELECT * FROM broker_app.Sell_Orders WHERE 1=0;
ALTER TABLE dw_bronze.stg_sell_orders ADD (stg_extraction_date TIMESTAMP);
