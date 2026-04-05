
CREATE TABLE Users (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL UNIQUE,
    password_hash VARCHAR2(255) NOT NULL,
    phone_number VARCHAR2(20),
    referral_code VARCHAR2(20),
    two_factor_enabled NUMBER(1) DEFAULT 0, -- 0=No, 1=Yes
    role VARCHAR2(20) DEFAULT 'USER', -- USER, ADMIN, STAFF
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE User_Address (
    address_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    address_line VARCHAR2(255),
    city VARCHAR2(100),
    country VARCHAR2(100),
    zip_code VARCHAR2(20),
    CONSTRAINT fk_addr_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Login_History (
    login_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    ip_address VARCHAR2(50),
    device_name VARCHAR2(100),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR2(20) DEFAULT 'SUCCESS',
    CONSTRAINT fk_login_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE API_Keys (
    key_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    api_key VARCHAR2(64) NOT NULL UNIQUE,
    secret_key VARCHAR2(64) NOT NULL,
    permissions VARCHAR2(4000), -- JSON String
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_api_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE KYC_Verification (
    kyc_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    status VARCHAR2(20) DEFAULT 'PENDING',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP,
    CONSTRAINT fk_kyc_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE KYC_Documents (
    doc_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kyc_id NUMBER NOT NULL,
    doc_type VARCHAR2(50),
    file_path VARCHAR2(255),
    CONSTRAINT fk_doc_kyc FOREIGN KEY (kyc_id) REFERENCES KYC_Verification(kyc_id)
);

CREATE TABLE Bank_Accounts (
    bank_account_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    bank_name VARCHAR2(100),
    account_number VARCHAR2(50),
    account_name VARCHAR2(100),
    is_verified NUMBER(1) DEFAULT 0,
    CONSTRAINT fk_bank_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- ==========================================================
-- 3. ASSET & ACCOUNTING (การเงินและสินทรัพย์)
-- ==========================================================

CREATE TABLE Assets (
    asset_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol VARCHAR2(10) NOT NULL UNIQUE, -- e.g., BTC, THB
    name VARCHAR2(100) NOT NULL,
    type VARCHAR2(20) NOT NULL, -- CRYPTO, FIAT
    decimals NUMBER DEFAULT 8
);

CREATE TABLE Accounts (
    account_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    account_type VARCHAR2(20) DEFAULT 'SPOT',
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_acc_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Portfolio (
    portfolio_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL UNIQUE,
    total_equity NUMBER(20, 8) DEFAULT 0,
    cash_balance NUMBER(20, 8) DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_port_acc FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
);

CREATE TABLE Holdings (
    holding_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL,
    asset_id NUMBER NOT NULL,
    quantity NUMBER(20, 8) DEFAULT 0,
    locked_qty NUMBER(20, 8) DEFAULT 0, -- ติดใน Order
    available_qty NUMBER(20, 8) DEFAULT 0, -- พร้อมขาย
    CONSTRAINT fk_hold_acc FOREIGN KEY (account_id) REFERENCES Accounts(account_id),
    CONSTRAINT fk_hold_asset FOREIGN KEY (asset_id) REFERENCES Assets(asset_id),
    CONSTRAINT uq_hold_acc_asset UNIQUE (account_id, asset_id)
);

CREATE TABLE Fiat_Transactions (
    fiat_txn_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL,
    bank_account_id NUMBER, 
    asset_id NUMBER NOT NULL,
    amount NUMBER(20, 8) NOT NULL,
    txn_type VARCHAR2(20) NOT NULL, -- DEPOSIT, WITHDRAW
    status VARCHAR2(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fiat_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_fiat_bank FOREIGN KEY (bank_account_id) REFERENCES Bank_Accounts(bank_account_id),
    CONSTRAINT fk_fiat_asset FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

-- ==========================================================
-- 4.( TRADING ENGINE )
-- ==========================================================

CREATE TABLE Trading_Pairs (
    pair_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol VARCHAR2(20) NOT NULL, -- e.g., BTC/THB
    base_asset_id NUMBER NOT NULL, -- e.g., BTC
    quote_asset_id NUMBER NOT NULL, -- e.g., THB
    status VARCHAR2(20) DEFAULT 'TRADING',
    CONSTRAINT fk_pair_base FOREIGN KEY (base_asset_id) REFERENCES Assets(asset_id),
    CONSTRAINT fk_pair_quote FOREIGN KEY (quote_asset_id) REFERENCES Assets(asset_id)
);

CREATE TABLE Market_Tickers (
    ticker_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pair_id NUMBER NOT NULL,
    last_price NUMBER(20, 8),
    high_24h NUMBER(20, 8),
    low_24h NUMBER(20, 8),
    volume_24h NUMBER(20, 8),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ticker_pair FOREIGN KEY (pair_id) REFERENCES Trading_Pairs(pair_id)
);

CREATE TABLE Tick_Data (
    tick_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pair_id NUMBER NOT NULL,
    price NUMBER(20, 8) NOT NULL,
    qty NUMBER(20, 8) NOT NULL,
    tick_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tick_pair FOREIGN KEY (pair_id) REFERENCES Trading_Pairs(pair_id)
);

-- ----------------------------------------------------------
--  แยก Buy_Orders และ Sell_Orders
-- ----------------------------------------------------------

CREATE TABLE Buy_Orders (
    buy_order_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL, -- จำเป็นต้องมีเพื่อระบุเจ้าของ
    pair_id NUMBER NOT NULL,
    price NUMBER(20, 8) NOT NULL, -- ราคาเสนอซื้อ
    quantity NUMBER(20, 8) NOT NULL, -- จำนวนที่จะซื้อ
    filled_qty NUMBER(20, 8) DEFAULT 0,
    status VARCHAR2(20) DEFAULT 'NEW', -- NEW, PARTIAL, FILLED, CANCELED
    order_type VARCHAR2(10) DEFAULT 'LIMIT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_buy_acc FOREIGN KEY (account_id) REFERENCES Accounts(account_id),
    CONSTRAINT fk_buy_pair FOREIGN KEY (pair_id) REFERENCES Trading_Pairs(pair_id)
);

CREATE TABLE Sell_Orders (
    sell_order_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL, -- จำเป็นต้องมีเพื่อระบุเจ้าของ
    pair_id NUMBER NOT NULL,
    price NUMBER(20, 8) NOT NULL, -- ราคาเสนอขาย
    quantity NUMBER(20, 8) NOT NULL, -- จำนวนที่จะขาย
    filled_qty NUMBER(20, 8) DEFAULT 0,
    status VARCHAR2(20) DEFAULT 'NEW',
    order_type VARCHAR2(10) DEFAULT 'LIMIT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sell_acc FOREIGN KEY (account_id) REFERENCES Accounts(account_id),
    CONSTRAINT fk_sell_pair FOREIGN KEY (pair_id) REFERENCES Trading_Pairs(pair_id)
);

-- ----------------------------------------------------------
--  Trades เชื่อม Buy/Sell คนละขา
-- ----------------------------------------------------------

CREATE TABLE Trades (
    trade_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pair_id NUMBER NOT NULL,
    buy_order_id NUMBER NOT NULL,
    sell_order_id NUMBER NOT NULL,
    price NUMBER(20, 8) NOT NULL, -- ราคาที่ Match ได้จริง
    quantity NUMBER(20, 8) NOT NULL,
    fee_amount NUMBER(20, 8) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_trade_pair FOREIGN KEY (pair_id) REFERENCES Trading_Pairs(pair_id),
    CONSTRAINT fk_trade_buy_ref FOREIGN KEY (buy_order_id) REFERENCES Buy_Orders(buy_order_id),
    CONSTRAINT fk_trade_sell_ref FOREIGN KEY (sell_order_id) REFERENCES Sell_Orders(sell_order_id)
);
