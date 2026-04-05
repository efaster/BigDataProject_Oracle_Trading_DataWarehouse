-- 1. Drop Reporting Views
DROP VIEW rpt_trading_performance;
DROP VIEW rpt_asset_holdings_by_tier;
DROP VIEW rpt_investor_behavior;

-- 2. Drop Mart Tables (Facts & Dimensions)
DROP TABLE fct_trades CASCADE CONSTRAINTS;
DROP TABLE fct_portfolio_snapshots CASCADE CONSTRAINTS;
DROP TABLE dim_users CASCADE CONSTRAINTS;
DROP TABLE dim_assets CASCADE CONSTRAINTS;
DROP TABLE dim_trading_pairs CASCADE CONSTRAINTS;

-- 3. Drop Staging Tables
DROP TABLE stg_users CASCADE CONSTRAINTS;
DROP TABLE stg_trades CASCADE CONSTRAINTS;
DROP TABLE stg_assets CASCADE CONSTRAINTS;
DROP TABLE stg_trading_pairs CASCADE CONSTRAINTS;

-- 4. Drop Metadata & Control Tables
DROP TABLE dbt_run_log CASCADE CONSTRAINTS;
DROP TABLE dbt_artifacts CASCADE CONSTRAINTS;

PROMPT 'DWH Cleanup Completed Successfully!';
