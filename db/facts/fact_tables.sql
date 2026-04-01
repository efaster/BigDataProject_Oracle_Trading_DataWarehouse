-- 2. FACT & ANALYSIS TABLES 
CREATE TABLE dw_silver.fact_trades (
    trade_id NUMBER PRIMARY KEY,
    pair_id NUMBER,
    price NUMBER(20, 8),
    quantity NUMBER(20, 8),
    total_value NUMBER(20, 8), 
    fee_amount NUMBER(20, 8),
    trade_time TIMESTAMP,
    extraction_date TIMESTAMP
);

CREATE TABLE dw_silver.fact_holdings (
    holding_id NUMBER PRIMARY KEY,
    account_id NUMBER,
    asset_id NUMBER,
    total_quantity NUMBER(20, 8),
    available_qty NUMBER(20, 8),
    locked_qty NUMBER(20, 8), 
    extraction_date TIMESTAMP
);

CREATE TABLE dw_silver.ana_user_behavior (
    user_id NUMBER PRIMARY KEY,
    account_age_days NUMBER,
    security_level VARCHAR2(20), 
    trade_frequency_count NUMBER,
    avg_trade_value NUMBER(20, 8)
);
