-- 1. DIMENSION TABLES 
CREATE TABLE dw_silver.dim_users (
    user_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER,
    username VARCHAR2(50),
    email VARCHAR2(100),
    two_factor_enabled NUMBER(1),
    status VARCHAR2(20),
    registration_date TIMESTAMP,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current NUMBER(1)
);

CREATE TABLE dw_silver.dim_assets (
    asset_id NUMBER PRIMARY KEY,
    symbol VARCHAR2(10),
    asset_name VARCHAR2(100),
    asset_type VARCHAR2(20)
);

CREATE TABLE dw_silver.dim_trading_pairs (
    pair_id NUMBER PRIMARY KEY,
    symbol VARCHAR2(20),
    base_asset_id NUMBER,
    quote_asset_id NUMBER
);

CREATE TABLE dw_silver.dim_portfolios (
    portfolio_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER,
    cash_balance NUMBER(20, 8),
    portfolio_tier VARCHAR2(20), 
    extraction_date TIMESTAMP
);

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
