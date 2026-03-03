BEGIN
    -- โหลดข้อมูล Users
    INSERT INTO dw_bronze.stg_users (user_id, username, email, two_factor_enabled, status, created_at, stg_valid_from, stg_is_current, stg_extraction_date)
    SELECT user_id, username, email, two_factor_enabled, status, created_at, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP 
    FROM broker_app.Users;

    -- โหลดข้อมูล Trades
    INSERT INTO dw_bronze.stg_trades (trade_id, pair_id, buy_order_id, sell_order_id, price, quantity, fee_amount, created_at, stg_extraction_date)
    SELECT trade_id, pair_id, buy_order_id, sell_order_id, price, quantity, fee_amount, created_at, CURRENT_TIMESTAMP 
    FROM broker_app.Trades;

    -- 🚀 โหลดข้อมูล Orders 
    INSERT INTO dw_bronze.stg_buy_orders (buy_order_id, account_id, pair_id, price, quantity, filled_qty, status, order_type, created_at, stg_extraction_date)
    SELECT buy_order_id, account_id, pair_id, price, quantity, filled_qty, status, order_type, created_at, CURRENT_TIMESTAMP FROM broker_app.Buy_Orders;

    INSERT INTO dw_bronze.stg_sell_orders (sell_order_id, account_id, pair_id, price, quantity, filled_qty, status, order_type, created_at, stg_extraction_date)
    SELECT sell_order_id, account_id, pair_id, price, quantity, filled_qty, status, order_type, created_at, CURRENT_TIMESTAMP FROM broker_app.Sell_Orders;

    -- โหลด Assets และ Trading Pairs
    INSERT INTO dw_bronze.stg_assets (asset_id, symbol, name, type, stg_valid_from, stg_is_current, stg_extraction_date)
    SELECT asset_id, symbol, name, type, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP FROM broker_app.Assets;
    
    INSERT INTO dw_bronze.stg_trading_pairs (pair_id, symbol, base_asset_id, quote_asset_id, status, stg_extraction_date)
    SELECT pair_id, symbol, base_asset_id, quote_asset_id, status, CURRENT_TIMESTAMP FROM broker_app.Trading_Pairs;

    -- โหลดข้อมูล Accounts, Portfolio และ Holdings
    INSERT INTO dw_bronze.stg_accounts (account_id, user_id, account_type, status, created_at, stg_valid_from, stg_is_current, stg_extraction_date)
    SELECT account_id, user_id, account_type, status, created_at, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP FROM broker_app.Accounts;

    INSERT INTO dw_bronze.stg_portfolio (portfolio_id, account_id, total_equity, cash_balance, updated_at, stg_valid_from, stg_is_current, stg_extraction_date)
    SELECT portfolio_id, account_id, total_equity, cash_balance, updated_at, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP FROM broker_app.Portfolio;

    INSERT INTO dw_bronze.stg_holdings (holding_id, account_id, asset_id, quantity, available_qty, stg_valid_from, stg_is_current, stg_extraction_date)
    SELECT holding_id, account_id, asset_id, quantity, available_qty, CURRENT_TIMESTAMP, 1, CURRENT_TIMESTAMP FROM broker_app.Holdings;

    COMMIT;
END;
/
