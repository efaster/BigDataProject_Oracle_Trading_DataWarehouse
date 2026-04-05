-- dbt-style logging metadata
CREATE TABLE IF NOT EXISTS dbt_run_log (
    run_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model_name VARCHAR2(100),
    status VARCHAR2(20),
    rows_affected NUMBER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error_message VARCHAR2(4000)
);

-- Watermarking metadata
CREATE TABLE IF NOT EXISTS dbt_artifacts (
    resource_name VARCHAR2(100) PRIMARY KEY,
    last_watermark TIMESTAMP,
    last_id NUMBER
);

-- Initialize Watermarks
MERGE INTO dbt_artifacts t USING (SELECT 'TRADES' AS name FROM DUAL) s ON (t.resource_name = s.name)
WHEN NOT MATCHED THEN INSERT (resource_name, last_id) VALUES (s.name, 0);

-- ETL: Run Staging Models (Extract & Load)
CREATE OR REPLACE PROCEDURE sp_run_stg_models AS
    v_last_id NUMBER;
    v_max_id NUMBER;
BEGIN
    -- 1. Incremental Load (Trades)
    SELECT last_id INTO v_last_id FROM dbt_artifacts WHERE resource_name = 'TRADES';
    SELECT NVL(MAX(trade_id), 0) INTO v_max_id FROM broker_app.Trades;

    IF v_max_id > v_last_id THEN
        INSERT INTO stg_trades (trade_id, pair_id, buy_order_id, sell_order_id, price, quantity, fee_amount, created_at)
        SELECT trade_id, pair_id, buy_order_id, sell_order_id, price, quantity, fee_amount, created_at 
        FROM broker_app.Trades WHERE trade_id > v_last_id;
        
        UPDATE dbt_artifacts SET last_id = v_max_id WHERE resource_name = 'TRADES';
    END IF;

    -- 2. Full Refresh (Users, Accounts, Assets, Pairs)
    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_users';
    INSERT INTO stg_users (user_id, username, email, status, created_at)
    SELECT user_id, username, email, status, created_at FROM broker_app.Users;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_accounts';
    INSERT INTO stg_accounts (account_id, user_id, status)
    SELECT account_id, user_id, status FROM broker_app.Accounts;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_assets';
    INSERT INTO stg_assets (asset_id, symbol, name, type)
    SELECT asset_id, symbol, name, type FROM broker_app.Assets;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_trading_pairs';
    INSERT INTO stg_trading_pairs (pair_id, symbol, base_asset_id, quote_asset_id, status)
    SELECT pair_id, symbol, base_asset_id, quote_asset_id, status FROM broker_app.Trading_Pairs;

    -- 3. Snapshot Data (Portfolio & Holdings)
    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_portfolio';
    INSERT INTO stg_portfolio (account_id, total_equity, cash_balance)
    SELECT account_id, total_equity, cash_balance FROM broker_app.Portfolio;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_holdings';
    INSERT INTO stg_holdings (holding_id, account_id, asset_id, quantity, available_qty)
    SELECT holding_id, account_id, asset_id, quantity, available_qty FROM broker_app.Holdings;

    -- 4. Combined Orders (Full Refresh for analysis)
    EXECUTE IMMEDIATE 'TRUNCATE TABLE stg_orders_all';
    INSERT INTO stg_orders_all (order_id, account_id, pair_id, price, quantity, order_type, side)
    SELECT buy_order_id, account_id, pair_id, price, quantity, order_type, 'BUY' FROM broker_app.Buy_Orders
    UNION ALL
    SELECT sell_order_id, account_id, pair_id, price, quantity, order_type, 'SELL' FROM broker_app.Sell_Orders;

    COMMIT;
END;
/

-- ETL: Run Mart Models (Transformation)
CREATE OR REPLACE PROCEDURE sp_run_mart_models AS
    v_now TIMESTAMP := SYSTIMESTAMP;
    v_end_date TIMESTAMP := TO_TIMESTAMP('9999-12-31', 'YYYY-MM-DD');
BEGIN
    -- 1. Dimensions
    
    -- dim_assets
    MERGE INTO dim_assets t USING stg_assets s ON (t.asset_id = s.asset_id)
    WHEN MATCHED THEN UPDATE SET t.symbol = s.symbol, t.asset_name = s.name, t.asset_type = s.type
    WHEN NOT MATCHED THEN INSERT (asset_id, symbol, asset_name, asset_type) VALUES (s.asset_id, s.symbol, s.name, s.type);

    -- dim_trading_pairs
    MERGE INTO dim_trading_pairs t USING stg_trading_pairs s ON (t.pair_id = s.pair_id)
    WHEN MATCHED THEN UPDATE SET t.symbol = s.symbol, t.base_asset_id = s.base_asset_id, t.quote_asset_id = s.quote_asset_id
    WHEN NOT MATCHED THEN INSERT (pair_id, symbol, base_asset_id, quote_asset_id) VALUES (s.pair_id, s.symbol, s.base_asset_id, s.quote_asset_id);

    -- dim_users (SCD Type 2)
    UPDATE dim_users t
    SET valid_to = v_now,
        is_current = 0
    WHERE is_current = 1
      AND EXISTS (
          SELECT 1 FROM stg_users s 
          WHERE s.user_id = t.user_id 
            AND (s.status <> t.status)
      );

    INSERT INTO dim_users (user_id, username, email, status, is_current, valid_from, valid_to)
    SELECT user_id, username, email, status, 1, v_now, v_end_date
    FROM stg_users s
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_users t 
        WHERE t.user_id = s.user_id AND t.is_current = 1
    );

    -- 2. Facts
    
    INSERT INTO fct_trades (trade_id, pair_id, price, quantity, total_value, fee_amount, trade_at)
    SELECT trade_id, pair_id, price, quantity, (price * quantity), fee_amount, created_at
    FROM stg_trades s WHERE NOT EXISTS (SELECT 1 FROM fct_trades t WHERE t.trade_id = s.trade_id);

    INSERT INTO fct_portfolio_snapshots (account_id, total_equity, cash_balance, captured_at)
    SELECT account_id, total_equity, cash_balance, v_now FROM stg_portfolio;

    DELETE FROM dim_portfolios;
    INSERT INTO dim_portfolios (account_id, cash_balance, portfolio_tier)
    SELECT account_id, cash_balance, 
           CASE WHEN cash_balance >= 1000000 THEN 'Whale' ELSE 'Retail' END
    FROM stg_portfolio;

    DELETE FROM fact_holdings;
    INSERT INTO fact_holdings (holding_id, account_id, asset_id, total_quantity, available_qty, locked_qty)
    SELECT holding_id, account_id, asset_id, quantity, available_qty, (quantity - available_qty)
    FROM stg_holdings;

    -- 3. Analysis Models (Simplified and robust)
    DELETE FROM ana_user_behavior;
    INSERT INTO ana_user_behavior (user_id, account_age_days, security_level, trade_frequency_count, avg_trade_value)
    SELECT 
        u.user_id,
        TRUNC(SYSDATE - CAST(u.created_at AS DATE)),
        'Basic',
        NVL(behavior.total_count, 0),
        NVL(behavior.avg_val, 0)
    FROM stg_users u
    LEFT JOIN (
        SELECT acc.user_id, COUNT(ft.trade_id) as total_count, AVG(ft.total_value) as avg_val
        FROM stg_accounts acc
        JOIN stg_orders_all ord ON acc.account_id = ord.account_id
        JOIN stg_trades st ON (ord.order_id = st.buy_order_id OR ord.order_id = st.sell_order_id)
        JOIN fct_trades ft ON st.trade_id = ft.trade_id
        GROUP BY acc.user_id
    ) behavior ON u.user_id = behavior.user_id;

    COMMIT;
END;
/

-- Main Pipeline Orchestrator
CREATE OR REPLACE PROCEDURE dbt_run AS
BEGIN
    sp_run_stg_models;
    sp_run_mart_models;
END;
/

PROMPT 'Fixed Comprehensive dbt-style Pipeline with SCD Type 2 Ready!';
