/* =====================================================================
   Script Name: Deploy_Gold_Views.sql
   Layer: Gold (Data Warehouse / Presentation Layer)
   Description: สร้าง Views สำหรับรายงานเชิงบริหาร (Executive Dashboards)
   ===================================================================== */

/* ---------------------------------------------------------------------
   VIEW 1: rpt_trading_performance
   รายงานที่ 1: ผลการดำเนินงานด้านการซื้อขาย (Volume & Revenue)
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW dw_gold.rpt_trading_performance AS
SELECT 
    TRUNC(t.trade_time) AS trade_date,
    a.asset_type,
    p.symbol AS trading_pair,
    COUNT(t.trade_id) AS total_trades,
    SUM(t.quantity) AS total_volume_assets,
    SUM(t.total_value) AS total_trading_value_thb,
    SUM(t.fee_amount) AS total_fee_revenue_thb
FROM dw_silver.fact_trades t
JOIN dw_silver.dim_trading_pairs p ON t.pair_id = p.pair_id
JOIN dw_silver.dim_assets a ON p.base_asset_id = a.asset_id
GROUP BY TRUNC(t.trade_time), a.asset_type, p.symbol;

/* ---------------------------------------------------------------------
   VIEW 2: rpt_asset_holdings_by_tier
   รายงานที่ 1: สถานะการถือครองและกลุ่มนักลงทุน (Wealth Concentration)
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW dw_gold.rpt_asset_holdings_by_tier AS
SELECT 
    p.portfolio_tier,
    a.asset_type,
    a.symbol AS asset_symbol,
    COUNT(DISTINCT h.account_id) AS total_investors,
    SUM(h.total_quantity) AS total_holding_balance,
    SUM(h.locked_qty) AS total_locked_in_orders
FROM dw_silver.fact_holdings h
JOIN dw_silver.dim_portfolios p ON h.account_id = p.account_id
JOIN dw_silver.dim_assets a ON h.asset_id = a.asset_id
GROUP BY p.portfolio_tier, a.asset_type, a.symbol;

/* ---------------------------------------------------------------------
   VIEW 3: rpt_investor_behavior
   รายงานที่ 2: วิเคราะห์พฤติกรรมเชิงลึกและคุณภาพลูกค้า (Investor Behavior)
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW dw_gold.rpt_investor_behavior AS
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
FROM dw_silver.dim_users u
JOIN dw_silver.ana_user_behavior b ON u.user_id = b.user_id
WHERE u.is_current = 1 
GROUP BY 
    u.status,
    b.security_level,
    CASE 
        WHEN b.account_age_days < 30 THEN 'New (<1 Month)'
        WHEN b.account_age_days BETWEEN 30 AND 90 THEN 'Growing (1-3 Months)'
        ELSE 'Loyal (>3 Months)'
    END;

PROMPT 'Deploy Gold Views Completed Successfully!';
