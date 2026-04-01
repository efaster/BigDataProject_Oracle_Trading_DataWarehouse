-- 1. ป้องกันราคาสินทรัพย์ และจำนวนการถือครองติดลบ (ยอมให้เป็น 0 ได้)
ALTER TABLE Holdings ADD CONSTRAINT chk_holdings_qty CHECK (quantity >= 0);
ALTER TABLE Holdings ADD CONSTRAINT chk_holdings_locked CHECK (locked_qty >= 0);
ALTER TABLE Holdings ADD CONSTRAINT chk_holdings_avail CHECK (available_qty >= 0);

-- 2. ป้องกันคำสั่งซื้อ/ขาย ที่ราคาหรือจำนวนติดลบหรือเป็นศูนย์ (ต้องมากกว่า 0 เท่านั้น)
ALTER TABLE Buy_Orders ADD CONSTRAINT chk_buy_price CHECK (price > 0);
ALTER TABLE Buy_Orders ADD CONSTRAINT chk_buy_qty CHECK (quantity > 0);

ALTER TABLE Sell_Orders ADD CONSTRAINT chk_sell_price CHECK (price > 0);
ALTER TABLE Sell_Orders ADD CONSTRAINT chk_sell_qty CHECK (quantity > 0);

-- 3. ป้องกันประวัติการเทรดที่ราคาหรือจำนวนติดลบ
ALTER TABLE Trades ADD CONSTRAINT chk_trade_price CHECK (price > 0);
ALTER TABLE Trades ADD CONSTRAINT chk_trade_qty CHECK (quantity > 0);
ALTER TABLE Trades ADD CONSTRAINT chk_trade_fee CHECK (fee_amount >= 0);

-- 4. ป้องกันการทำธุรกรรมเงินเฟียต (ฝาก/ถอน) ที่จำนวนเงินติดลบ
ALTER TABLE Fiat_Transactions ADD CONSTRAINT chk_fiat_amount CHECK (amount > 0);
