BEGIN
    -- 1. โหลดข้อมูล Assets
    INSERT INTO dw_silver.dim_assets (asset_id, symbol, asset_name, asset_type)
    SELECT asset_id, symbol, name, type 
    FROM dw_bronze.stg_assets
    WHERE stg_is_current = 1;

    -- 2. โหลดข้อมูล Trading Pairs
    INSERT INTO dw_silver.dim_trading_pairs (pair_id, symbol, base_asset_id, quote_asset_id)
    SELECT pair_id, symbol, base_asset_id, quote_asset_id 
    FROM dw_bronze.stg_trading_pairs;

    -- 3. โหลดและทำความสะอาด Users
    INSERT INTO dw_silver.dim_users (
        user_id, username, email, two_factor_enabled, status, 
        registration_date, valid_from, valid_to, is_current
    )
    SELECT 
        user_id, 
        username, 
        LOWER(email), -- แปลง Email เป็นตัวพิมพ์เล็ก
        two_factor_enabled, 
        UPPER(status), -- แปลง Status เป็นตัวพิมพ์ใหญ่
        created_at, stg_valid_from, stg_valid_to, stg_is_current
    FROM dw_bronze.stg_users;

    -- 4. โหลดและจัดกลุ่ม Portfolio (Whale / Retail)
    INSERT INTO dw_silver.dim_portfolios (account_id, cash_balance, portfolio_tier, extraction_date)
    SELECT 
        account_id, 
        cash_balance,
        CASE 
            WHEN cash_balance >= 1000000 THEN 'Whale' 
            ELSE 'Retail' 
        END as portfolio_tier,
        stg_extraction_date
    FROM dw_bronze.stg_portfolio;

    -- 5. โหลดและคำนวณ Fact Holdings (คำนวณ Locked Qty)
    INSERT INTO dw_silver.fact_holdings (
        holding_id, account_id, asset_id, total_quantity, available_qty, locked_qty, extraction_date
    )
    SELECT 
        holding_id, 
        account_id, 
        asset_id, 
        quantity as total_quantity, 
        available_qty,
        (quantity - available_qty) as locked_qty,
        stg_extraction_date
    FROM dw_bronze.stg_holdings
    WHERE stg_is_current = 1;

    -- 6. โหลดและคำนวณ Fact Trades (คำนวณ Total Value)
    INSERT INTO dw_silver.fact_trades (
        trade_id, pair_id, price, quantity, total_value, fee_amount, trade_time, extraction_date
    )
    SELECT 
        trade_id, 
        pair_id, 
        price, 
        quantity, 
        (price * quantity) as total_value, 
        fee_amount, 
        created_at,
        stg_extraction_date
    FROM dw_bronze.stg_trades;

    -- 7. วิเคราะห์พฤติกรรม User (Behavior Analysis) 
    INSERT INTO dw_silver.ana_user_behavior (
        user_id, account_age_days, security_level, trade_frequency_count, avg_trade_value
    )
    SELECT 
        u.user_id,
        TRUNC(SYSDATE - CAST(u.created_at AS DATE)) as account_age,
        CASE WHEN u.two_factor_enabled = 1 THEN 'High' ELSE 'Basic' END as security_level,
        COUNT(t.trade_id) as freq,
        NVL(AVG(t.price * t.quantity), 0) as avg_val
    FROM dw_bronze.stg_users u
    LEFT JOIN dw_bronze.stg_accounts a ON u.user_id = a.user_id
    -- หาว่าบัญชีนี้มีใบสั่งซื้อหรือขายหมายเลขอะไรบ้าง
    LEFT JOIN (
        SELECT buy_order_id as order_id, account_id FROM dw_bronze.stg_buy_orders
        UNION ALL
        SELECT sell_order_id as order_id, account_id FROM dw_bronze.stg_sell_orders
    ) ord ON a.account_id = ord.account_id
    -- เอาใบสั่งซื้อ/ขายนั้นไปจับคู่กับตาราง Trade ที่สำเร็จแล้ว
    LEFT JOIN dw_bronze.stg_trades t ON (ord.order_id = t.buy_order_id OR ord.order_id = t.sell_order_id)
    GROUP BY u.user_id, u.created_at, u.two_factor_enabled;

    COMMIT;
END;
/
