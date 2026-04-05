-- Function: Calculate total trade value (including fees)
CREATE OR REPLACE FUNCTION fn_calc_total_trade_value (
    p_price NUMBER,
    p_qty NUMBER,
    p_fee NUMBER
) RETURN NUMBER IS
BEGIN
    RETURN (p_price * p_qty) + NVL(p_fee, 0);
END;
/

-- Function: Asset Categorization
CREATE OR REPLACE FUNCTION fn_get_asset_category (
    p_asset_type VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    RETURN CASE 
        WHEN UPPER(p_asset_type) IN ('BTC', 'ETH', 'SOL') THEN 'Major Crypto'
        WHEN UPPER(p_asset_type) IN ('USDT', 'USDC', 'BUSD') THEN 'Stablecoin'
        ELSE 'Altcoin/Other'
    END;
END;
/

-- Function: Account Age Calculation
CREATE OR REPLACE FUNCTION fn_get_account_age_years (
    p_created_at TIMESTAMP
) RETURN NUMBER IS
BEGIN
    RETURN ROUND(MONTHS_BETWEEN(SYSDATE, CAST(p_created_at AS DATE)) / 12, 2);
END;
/

PROMPT 'Functions Created Successfully!';
