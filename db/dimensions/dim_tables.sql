-- Dimension: Users (SCD Type 2)
CREATE TABLE dim_users (
    user_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER,
    username VARCHAR2(100),
    email VARCHAR2(150),
    status VARCHAR2(20),
    is_current NUMBER(1) DEFAULT 1,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
);

-- Dimension: Assets (SCD Type 1)
CREATE TABLE dim_assets (
    asset_id NUMBER PRIMARY KEY,
    symbol VARCHAR2(20),
    asset_name VARCHAR2(100),
    asset_type VARCHAR2(50)
);

-- Dimension: Trading Pairs
CREATE TABLE dim_trading_pairs (
    pair_id NUMBER PRIMARY KEY,
    symbol VARCHAR2(50),
    base_asset_id NUMBER,
    quote_asset_id NUMBER
);

-- Dimension: Portfolios (for Tiering Analysis)
CREATE TABLE dim_portfolios (
    account_id NUMBER PRIMARY KEY,
    cash_balance NUMBER,
    portfolio_tier VARCHAR2(20),
    extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: User Behavior Analysis (ana_user_behavior)
CREATE TABLE ana_user_behavior (
    user_id NUMBER PRIMARY KEY,
    account_age_days NUMBER,
    security_level VARCHAR2(20),
    trade_frequency_count NUMBER,
    avg_trade_value NUMBER,
    is_current NUMBER(1) DEFAULT 1
);

-- Dimension: Date (Calendar Dimension) - NEW
CREATE TABLE dim_date (
    date_id NUMBER PRIMARY KEY, -- Format: YYYYMMDD
    full_date DATE NOT NULL,
    day_of_month NUMBER,
    day_name VARCHAR2(20),
    day_of_week NUMBER,
    month_number NUMBER,
    month_name VARCHAR2(20),
    quarter NUMBER,
    year_number NUMBER,
    is_weekend NUMBER(1),
    is_holiday NUMBER(1) DEFAULT 0
);

PROMPT 'Dimension Models Created Successfully!';
