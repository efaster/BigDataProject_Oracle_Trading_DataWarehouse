-- Fact: Trades (Event Records)
CREATE TABLE fct_trades (
    trade_id NUMBER PRIMARY KEY,
    pair_id NUMBER,
    price NUMBER,
    quantity NUMBER,
    total_value NUMBER,
    fee_amount NUMBER,
    trade_at TIMESTAMP,
    extraction_at TIMESTAMP
);

-- Fact: Portfolio (Snapshots)
CREATE TABLE fct_portfolio_snapshots (
    snapshot_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER,
    total_equity NUMBER,
    cash_balance NUMBER,
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fact: Holdings (Asset Balances)
CREATE TABLE fact_holdings (
    holding_id NUMBER PRIMARY KEY,
    account_id NUMBER,
    asset_id NUMBER,
    total_quantity NUMBER,
    available_qty NUMBER,
    locked_qty NUMBER,
    extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

PROMPT 'Fact Models Created Successfully!';
