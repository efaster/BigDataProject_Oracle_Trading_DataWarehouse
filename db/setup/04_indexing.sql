-- 1. สร้าง Index สำหรับ Foreign Keys 
CREATE INDEX idx_holdings_acc ON Holdings(account_id);
CREATE INDEX idx_holdings_asset ON Holdings(asset_id);
CREATE INDEX idx_buy_acc ON Buy_Orders(account_id);
CREATE INDEX idx_sell_acc ON Sell_Orders(account_id);
CREATE INDEX idx_fiat_user ON Fiat_Transactions(user_id);

-- 2. สร้าง Index สำหรับคอลัมน์ที่ถูกค้นหา (WHERE clause) หรือจัดเรียง (ORDER BY) บ่อยที่สุด
CREATE INDEX idx_buy_status ON Buy_Orders(pair_id, status);
CREATE INDEX idx_sell_status ON Sell_Orders(pair_id, status);

-- เวลากราฟเรียกดูประวัติการเทรดย้อนหลัง 
CREATE INDEX idx_trades_pair_time ON Trades(pair_id, created_at DESC);
CREATE INDEX idx_tick_pair_time ON Tick_Data(pair_id, tick_time DESC);

-- เวลาค้นหา User ด้วย Email หรือ เช็คสถานะ KYC
CREATE INDEX idx_users_email_login ON Users(email, status);
CREATE INDEX idx_kyc_status ON KYC_Verification(status);
