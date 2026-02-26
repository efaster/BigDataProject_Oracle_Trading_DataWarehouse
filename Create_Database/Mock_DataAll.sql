-- ==========================================================
-- 1. เตรียม Assets และ Trading Pairs ทั้งหมด
-- ==========================================================
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('THB', 'Thai Baht', 'FIAT', 2);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('BTC', 'Bitcoin', 'CRYPTO', 8);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('ETH', 'Ethereum', 'CRYPTO', 8);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('PTT', 'PTT Public Company', 'STOCK', 2);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('AOT', 'Airports of Thailand', 'STOCK', 2);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('CPALL', 'CP ALL Public Company', 'STOCK', 2);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('ADVANC', 'Advanced Info Service', 'STOCK', 2);
INSERT INTO Assets (symbol, name, type, decimals) VALUES ('SCC', 'Siam Cement Group', 'STOCK', 2);
COMMIT;

DECLARE
    v_thb_id NUMBER;
BEGIN
    SELECT asset_id INTO v_thb_id FROM Assets WHERE symbol = 'THB';
    FOR r IN (SELECT asset_id, symbol FROM Assets WHERE type IN ('CRYPTO', 'STOCK')) LOOP
        INSERT INTO Trading_Pairs (symbol, base_asset_id, quote_asset_id) 
        VALUES (r.symbol || '/THB', r.asset_id, v_thb_id);
    END LOOP;
    COMMIT;
END;
/

-- ==========================================================
-- 2. สร้าง User 150 คน (100 Crypto Traders + 50 Stock Investors)
-- ==========================================================
DECLARE
    v_user_id NUMBER; v_account_id NUMBER;
    v_btc_id NUMBER; v_eth_id NUMBER;
BEGIN
    SELECT asset_id INTO v_btc_id FROM Assets WHERE symbol = 'BTC';
    SELECT asset_id INTO v_eth_id FROM Assets WHERE symbol = 'ETH';

    -- กลุ่ม 1: Crypto Traders (100 คน)
    FOR i IN 1..100 LOOP
        INSERT INTO Users (username, email, password_hash)
        VALUES ('crypto_trader_' || i, 'crypto_' || i || '@demo.com', 'pwd') RETURNING user_id INTO v_user_id;
        INSERT INTO Accounts (user_id, account_type) VALUES (v_user_id, 'SPOT') RETURNING account_id INTO v_account_id;
        INSERT INTO Portfolio (account_id, cash_balance) VALUES (v_account_id, 10000000); -- เพิ่มเงินต้นให้เยอะขึ้น
        INSERT INTO Holdings (account_id, asset_id, quantity, available_qty) VALUES (v_account_id, v_btc_id, 50, 50);
        INSERT INTO Holdings (account_id, asset_id, quantity, available_qty) VALUES (v_account_id, v_eth_id, 500, 500);
    END LOOP;

    -- กลุ่ม 2: Stock Investors (50 คน)
    FOR i IN 1..50 LOOP
        INSERT INTO Users (username, email, password_hash)
        VALUES ('stock_investor_' || i, 'stock_' || i || '@demo.com', 'pwd') RETURNING user_id INTO v_user_id;
        INSERT INTO Accounts (user_id, account_type) VALUES (v_user_id, 'SPOT') RETURNING account_id INTO v_account_id;
        INSERT INTO Portfolio (account_id, cash_balance) VALUES (v_account_id, 20000000);
        FOR r IN (SELECT asset_id FROM Assets WHERE type = 'STOCK') LOOP
            INSERT INTO Holdings (account_id, asset_id, quantity, available_qty) VALUES (v_account_id, r.asset_id, 100000, 100000);
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ==========================================================
-- 3. จำลองการเทรด 2,000 ไม้ (แก้ไขจุด Check Constraint Error)
-- ==========================================================
DECLARE
    v_buyer_acc NUMBER; v_seller_acc NUMBER; v_buy_id NUMBER; v_sell_id NUMBER;
    v_price NUMBER; v_qty NUMBER; v_pair_id NUMBER; v_base_id NUMBER; v_symbol VARCHAR2(20);
BEGIN
    FOR i IN 1..2000 LOOP
        -- 3.1 สุ่มเลือกคู่เทรดมา 1 คู่
        SELECT pair_id, base_asset_id, symbol INTO v_pair_id, v_base_id, v_symbol 
        FROM (SELECT * FROM Trading_Pairs ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;

        -- 3.2 กำหนดราคาและจำนวน
        IF v_symbol LIKE 'BTC%' THEN v_price := 2300000; v_qty := 0.05;
        ELSIF v_symbol LIKE 'ETH%' THEN v_price := 120000; v_qty := 1;
        ELSE v_price := ROUND(DBMS_RANDOM.VALUE(50, 200), 2); v_qty := 100;
        END IF;

        -- 3.3 สุ่มคนซื้อ (ใครก็ได้ที่มีเงินสดพอ)
        BEGIN
            SELECT account_id INTO v_buyer_acc 
            FROM (SELECT account_id FROM Portfolio WHERE cash_balance >= (v_price * v_qty) ORDER BY DBMS_RANDOM.VALUE) 
            WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN CONTINUE; END;

        -- 3.4 สุ่มคนขาย (ต้องมีของพอขาย และไม่ใช่คนเดียวกับคนซื้อ)
        BEGIN
            SELECT account_id INTO v_seller_acc 
            FROM (SELECT account_id FROM Holdings WHERE asset_id = v_base_id AND available_qty >= v_qty AND account_id != v_buyer_acc ORDER BY DBMS_RANDOM.VALUE) 
            WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN CONTINUE; END;

        -- 3.5 สร้าง Order 
        INSERT INTO Buy_Orders (account_id, pair_id, price, quantity, status) 
        VALUES (v_buyer_acc, v_pair_id, v_price, v_qty, 'NEW') RETURNING buy_order_id INTO v_buy_id;
        
        INSERT INTO Sell_Orders (account_id, pair_id, price, quantity, status) 
        VALUES (v_seller_acc, v_pair_id, v_price, v_qty, 'NEW') RETURNING sell_order_id INTO v_sell_id;
        
        -- 3.6 ล็อคของคนขาย (ย้ายจาก available ไป locked) 
        UPDATE Holdings 
        SET available_qty = available_qty - v_qty, 
            locked_qty = locked_qty + v_qty 
        WHERE account_id = v_seller_acc AND asset_id = v_base_id;

        -- 3.7 เรียกใช้ Procedure ของคุณ
        Execute_Trade_Match(v_buy_id, v_sell_id, v_price, v_qty);
    END LOOP;

    UPDATE Trades SET created_at = SYSDATE - DBMS_RANDOM.VALUE(0, 45);
    UPDATE Buy_Orders SET created_at = SYSDATE - DBMS_RANDOM.VALUE(0, 45);
    UPDATE Sell_Orders SET created_at = SYSDATE - DBMS_RANDOM.VALUE(0, 45);
    
    COMMIT;
END;
/
