-- Report: Trading Performance (Volume & Revenue)
-- ใช้ dim_date เพื่อดึงชื่อวันและไตรมาส
CREATE OR REPLACE VIEW rpt_trading_performance AS
SELECT 
    d.year_number,
    d.month_name,
    d.day_name,
    a.asset_type,
    p.symbol AS trading_pair,
    COUNT(t.trade_id) AS total_trades,
    SUM(t.quantity) AS total_volume_assets,
    SUM(t.total_value) AS total_trading_value_thb,
    SUM(t.fee_amount) AS total_fee_revenue_thb
FROM fct_trades t
JOIN dim_date d ON TO_NUMBER(TO_CHAR(t.trade_at, 'YYYYMMDD')) = d.date_id
JOIN dim_trading_pairs p ON t.pair_id = p.pair_id
JOIN dim_assets a ON p.base_asset_id = a.asset_id
GROUP BY d.year_number, d.month_name, d.day_name, a.asset_type, p.symbol;

-- Report: Asset Holdings & Wealth Concentration
CREATE OR REPLACE VIEW rpt_asset_holdings_by_tier AS
SELECT 
    p.portfolio_tier,
    a.asset_type,
    a.symbol AS asset_symbol,
    COUNT(DISTINCT h.account_id) AS total_investors,
    SUM(h.total_quantity) AS total_holding_balance,
    SUM(h.locked_qty) AS total_locked_in_orders
FROM fact_holdings h
JOIN dim_portfolios p ON h.account_id = p.account_id
JOIN dim_assets a ON h.asset_id = a.asset_id
GROUP BY p.portfolio_tier, a.asset_type, a.symbol;

-- Report: Investor Behavior & Quality Analysis
-- ใช้ข้อมูลจาก dim_users (SCD Type 2) เฉพาะตัวที่เป็นสถานะปัจจุบัน (is_current = 1)
CREATE OR REPLACE VIEW rpt_investor_behavior AS
SELECT 
    u.status AS account_status,
    b.security_level,
    CASE 
        WHEN b.account_age_days < 30 THEN 'New (<1 Month)'
        WHEN b.account_age_days BETWEEN 30 AND 90 THEN 'Growing (1-3 Months)'
        ELSE 'Loyal (>3 Months)'
    END AS customer_loyalty_segment,
    COUNT(u.user_id) AS total_users,
    SUM(b.trade_frequency_count) AS total_trades_made,
    ROUND(AVG(b.trade_frequency_count), 2) AS avg_trades_per_user,
    ROUND(AVG(b.avg_trade_value), 2) AS avg_order_size_thb
FROM dim_users u
JOIN ana_user_behavior b ON u.user_id = b.user_id
WHERE u.is_current = 1 
GROUP BY 
    u.status,
    b.security_level,
    CASE 
        WHEN b.account_age_days < 30 THEN 'New (<1 Month)'
        WHEN b.account_age_days BETWEEN 30 AND 90 THEN 'Growing (1-3 Months)'
        ELSE 'Loyal (>3 Months)'
    END;

PROMPT 'Deploy Reports with Date Dimension Completed Successfully!';
