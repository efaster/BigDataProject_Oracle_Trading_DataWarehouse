BEGIN
    -- เพื่อป้องกันข้อมูลซ้ำ (Idempotency)
    -- 1. โหลดข้อมูล Assets
    MERGE INTO dw_silver.dim_assets t
    USING (SELECT asset_id, symbol, name, type FROM dw_bronze.stg_assets WHERE stg_is_current = 1) s
    ON (t.asset_id = s.asset_id)
    WHEN MATCHED THEN 
        UPDATE SET t.symbol = s.symbol, t.asset_name = s.name, t.asset_type = s.type
    WHEN NOT MATCHED THEN
        INSERT (asset_id, symbol, asset_name, asset_type)
        VALUES (s.asset_id, s.symbol, s.name, s.type);

    -- 2. โหลดข้อมูล Trading Pairs
    MERGE INTO dw_silver.dim_trading_pairs t
    USING dw_bronze.stg_trading_pairs s
    ON (t.pair_id = s.pair_id)
    WHEN MATCHED THEN
        UPDATE SET t.symbol = s.symbol
    WHEN NOT MATCHED THEN
        INSERT (pair_id, symbol, base_asset_id, quote_asset_id)
        VALUES (s.pair_id, s.symbol, s.base_asset_id, s.quote_asset_id);

    --  SCD Type 2 สำหรับ Users
    -- 3.1 ปิด Record เก่าที่มีการเปลี่ยนแปลงข้อมูล (Expire old records)
    UPDATE dw_silver.dim_users u
    SET u.valid_to = SYSTIMESTAMP,
        u.is_current = 0
    WHERE u.is_current = 1
    AND EXISTS (
        SELECT 1 FROM dw_bronze.stg_users s
        WHERE s.user_id = u.user_id
        -- เช็คว่า Email หรือ Status มีการเปลี่ยนแปลงไหม
        AND (LOWER(s.email) <> u.email OR UPPER(s.status) <> u.status)
    );

    -- 3.2 โหลดข้อมูลใหม่ 
    INSERT INTO dw_silver.dim_users (
        user_id, username, email, two_factor_enabled, status, 
        registration_date, valid_from, valid_to, is_current
    )
    SELECT 
        user_id, 
        username, 
        NVL(LOWER(email), 'unknown@email.com'),
        NVL(two_factor_enabled, 0), 
        UPPER(status), 
        created_at, 
        SYSTIMESTAMP,
        TO_TIMESTAMP('9999-12-31','YYYY-MM-DD'),
        1 -- ข้อมูลชุดนี้คือ Current
    FROM dw_bronze.stg_users s
    WHERE NOT EXISTS (
        -- จะ Insert ก็ต่อเมื่อไม่มี record ที่เป็น Current ของ User คนนั้นๆ อยู่ในระบบ
        SELECT 1 FROM dw_silver.dim_users u 
        WHERE u.user_id = s.user_id AND u.is_current = 1
    );

    -- 4. โหลดและจัดกลุ่ม Portfolio (เพิ่มการจัดการค่า NULL)
    -- ใช้ DELETE + INSERT เพื่อให้ได้ข้อมูลล่าสุด (Refresh Strategy)
    DELETE FROM dw_silver.dim_portfolios; 
    INSERT INTO dw_silver.dim_portfolios (account_id, cash_balance, portfolio_tier, extraction_date)
    SELECT 
        account_id, 
        NVL(cash_balance, 0),  -- ป้องกันเงินในบัญชีเป็น NULL
        CASE 
            WHEN cash_balance >= 1000000 THEN 'Whale' 
            ELSE 'Retail' 
        END as portfolio_tier,
        stg_extraction_date
    FROM dw_bronze.stg_portfolio;

    -- 

    -- 5. โหลด Fact Holdings (เพิ่ม Data Validation)
    DELETE FROM dw_silver.fact_holdings;
    INSERT INTO dw_silver.fact_holdings (
        holding_id, account_id, asset_id, total_quantity, available_qty, locked_qty, extraction_date
    )
    SELECT 
        holding_id, 
        account_id, 
        asset_id, 
        quantity, 
        available_qty,
        (quantity - available_qty),
        stg_extraction_date
    FROM dw_bronze.stg_holdings
    WHERE stg_is_current = 1
    AND quantity >= 0; --  Data Validation: จำนวนเหรียญต้องไม่ติดลบ

    -- 6. โหลด Fact Trades (เพิ่ม Data Validation และคำนวณ)
    -- ใช้การเช็คข้อมูลซ้ำจาก trade_id เดิม
    INSERT INTO dw_silver.fact_trades (
        trade_id, pair_id, price, quantity, total_value, fee_amount, trade_time, extraction_date
    )
    SELECT 
        trade_id, 
        pair_id, 
        price, 
        quantity, 
        (price * quantity), 
        NVL(fee_amount, 0),
        created_at,
        stg_extraction_date
    FROM dw_bronze.stg_trades s
    WHERE NOT EXISTS (SELECT 1 FROM dw_silver.fact_trades t WHERE t.trade_id = s.trade_id)
    AND price > 0 AND quantity > 0; --  Validation: ราคาและจำนวนต้องมากกว่า 0

    -- 7. วิเคราะห์พฤติกรรม User (Behavior Analysis) 
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dw_silver.ana_user_behavior';
    INSERT INTO dw_silver.ana_user_behavior (
        user_id, account_age_days, security_level, trade_frequency_count, avg_trade_value
    )
    SELECT 
        u.user_id,
        TRUNC(SYSDATE - CAST(u.created_at AS DATE)),
        CASE WHEN u.two_factor_enabled = 1 THEN 'High' ELSE 'Basic' END,
        COUNT(t.trade_id),
        NVL(AVG(t.price * t.quantity), 0)
    FROM dw_bronze.stg_users u
    LEFT JOIN dw_bronze.stg_accounts a ON u.user_id = a.user_id
    LEFT JOIN (
        SELECT buy_order_id as order_id, account_id FROM dw_bronze.stg_buy_orders
        UNION ALL
        SELECT sell_order_id as order_id, account_id FROM dw_bronze.stg_sell_orders
    ) ord ON a.account_id = ord.account_id
    LEFT JOIN dw_bronze.stg_trades t ON (ord.order_id = t.buy_order_id OR ord.order_id = t.sell_order_id)
    GROUP BY u.user_id, u.created_at, u.two_factor_enabled;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
