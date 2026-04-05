-- Staging: Users
CREATE TABLE stg_users (
    user_id NUMBER,
    username VARCHAR2(100),
    email VARCHAR2(150),
    two_factor_enabled NUMBER(1),
    status VARCHAR2(20),
    created_at TIMESTAMP,
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Accounts
CREATE TABLE stg_accounts (
    account_id NUMBER,
    user_id NUMBER,
    status VARCHAR2(20),
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Trades
CREATE TABLE stg_trades (
    trade_id NUMBER,
    pair_id NUMBER,
    buy_order_id NUMBER,
    sell_order_id NUMBER,
    price NUMBER,
    quantity NUMBER,
    fee_amount NUMBER,
    created_at TIMESTAMP,
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Assets
CREATE TABLE stg_assets (
    asset_id NUMBER,
    symbol VARCHAR2(20),
    name VARCHAR2(100),
    type VARCHAR2(50),
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Portfolio
CREATE TABLE stg_portfolio (
    account_id NUMBER,
    total_equity NUMBER,
    cash_balance NUMBER,
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Holdings
CREATE TABLE stg_holdings (
    holding_id NUMBER,
    account_id NUMBER,
    asset_id NUMBER,
    quantity NUMBER,
    available_qty NUMBER,
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Orders (Combined for analysis)
CREATE TABLE stg_orders_all (
    order_id NUMBER,
    account_id NUMBER,
    pair_id NUMBER,
    price NUMBER,
    quantity NUMBER,
    order_type VARCHAR2(10),
    side VARCHAR2(10),
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging: Trading Pairs
CREATE TABLE stg_trading_pairs (
    pair_id NUMBER,
    symbol VARCHAR2(50),
    base_asset_id NUMBER,
    quote_asset_id NUMBER,
    status VARCHAR2(20),
    extraction_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

PROMPT 'Staging Models Created Successfully!';
