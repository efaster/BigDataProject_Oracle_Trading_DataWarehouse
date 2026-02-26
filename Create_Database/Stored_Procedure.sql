CREATE OR REPLACE PROCEDURE Execute_Trade_Match (
    p_buy_order_id IN NUMBER,
    p_sell_order_id IN NUMBER,
    p_match_price IN NUMBER,
    p_match_qty IN NUMBER
) AS
    v_buyer_acc NUMBER;
    v_seller_acc NUMBER;
    v_pair_id NUMBER;
    v_base_asset NUMBER;
    v_total_value NUMBER := p_match_price * p_match_qty;
    v_fee_amount NUMBER; 
BEGIN
    -- คำนวนค่า Free
    v_fee_amount := v_total_value * 0.0025;

    -- 1. สืบหาข้อมูลเจ้าของ Order และคู่เหรียญ
    SELECT account_id, pair_id INTO v_buyer_acc, v_pair_id FROM Buy_Orders WHERE buy_order_id = p_buy_order_id;
    SELECT account_id INTO v_seller_acc FROM Sell_Orders WHERE sell_order_id = p_sell_order_id;
    SELECT base_asset_id INTO v_base_asset FROM Trading_Pairs WHERE pair_id = v_pair_id;

    -- 2. อัปเดตใบสั่งซื้อ (Buy Order)
    UPDATE Buy_Orders 
    SET filled_qty = filled_qty + p_match_qty,
        status = CASE WHEN quantity <= filled_qty + p_match_qty THEN 'FILLED' ELSE 'PARTIAL' END
    WHERE buy_order_id = p_buy_order_id;

    -- 3. อัปเดตใบสั่งขาย (Sell Order)
    UPDATE Sell_Orders 
    SET filled_qty = filled_qty + p_match_qty,
        status = CASE WHEN quantity <= filled_qty + p_match_qty THEN 'FILLED' ELSE 'PARTIAL' END
    WHERE sell_order_id = p_sell_order_id;

    -- 4. หักเงินสดคนซื้อ (จาก Portfolio)
    UPDATE Portfolio 
    SET cash_balance = cash_balance - v_total_value 
    WHERE account_id = v_buyer_acc;

    -- 5. เพิ่มเหรียญให้คนซื้อ (ใช้ MERGE เผื่อคนซื้อเพิ่งเคยเทรดเหรียญนี้ครั้งแรก)
    MERGE INTO Holdings h
    USING (SELECT v_buyer_acc AS acc_id, v_base_asset AS ast_id FROM DUAL) src
    ON (h.account_id = src.acc_id AND h.asset_id = src.ast_id)
    WHEN MATCHED THEN
        UPDATE SET available_qty = available_qty + p_match_qty, quantity = quantity + p_match_qty
    WHEN NOT MATCHED THEN
        INSERT (account_id, asset_id, quantity, locked_qty, available_qty)
        VALUES (src.acc_id, src.ast_id, p_match_qty, 0, p_match_qty);

    -- 6. หักเหรียญที่ล็อคไว้ของคนขาย และเพิ่มเงินสดให้คนขาย
    UPDATE Holdings 
    SET locked_qty = locked_qty - p_match_qty, quantity = quantity - p_match_qty 
    WHERE account_id = v_seller_acc AND asset_id = v_base_asset;

    UPDATE Portfolio 
    SET cash_balance = cash_balance + v_total_value 
    WHERE account_id = v_seller_acc;

    -- 7. บันทึกประวัติลงตาราง Trades 
    INSERT INTO Trades (pair_id, buy_order_id, sell_order_id, price, quantity, fee_amount)
    VALUES (v_pair_id, p_buy_order_id, p_sell_order_id, p_match_price, p_match_qty, v_fee_amount);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; 
        RAISE;  
END;
/
