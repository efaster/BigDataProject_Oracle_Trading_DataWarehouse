# 🏗️ Oracle Data Warehouse - Trading Platform | Data Engineering Implementation

A comprehensive **enterprise data warehouse (EDW)** and **ETL pipeline** built with **Oracle SQL & PL/SQL**, designed for a trading/brokerage platform. This project demonstrates production-grade data engineering practices including dimensional modeling, Slowly Changing Dimensions (SCD Type 2), star schema design, performance optimization, and multi-layer data transformation.

---

## 📌 Project Overview

This is a full-stack data engineering solution that transforms raw transactional data from a broker application into an analytical data warehouse. The architecture follows the **medallion pattern** (Bronze → Silver → Gold) with emphasis on data quality, dimensional integrity, and analytical readiness.

**Key Features:**

- ✅ **SCD Type 2 Implementation** - Track historical dimensions with validity periods
- ✅ **Star Schema Design** - Optimized for OLAP queries and reporting
- ✅ **Multi-layer ETL Pipeline** - Segregated source, staging, and analytical layers
- ✅ **Data Quality Framework** - Constraints, validations, and audit trails
- ✅ **Performance Optimization** - Strategic indexing and partitioning strategy
- ✅ **Reproducible Pipeline** - Idempotent load processes with extraction dates

---

## 🏛️ Data Architecture

### Medallion Pattern (Three-Layer Architecture)

```
                    OLTP Source
                        ↓
        ┌───────────────────────────────┐
        │   BRONZE LAYER (STAGING)      │
        │   - Raw data as-is            │
        │   - SCD flags added           │
        │   - Extraction tracking       │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │   SILVER LAYER (CONFORMED)    │
        │   - Data cleaning & validation│
        │   - Business calculations     │
        │   - Dimensional tables (SCD2) │
        │   - Fact tables               │
        └───────────────────────────────┘
                        ↓
        ┌───────────────────────────────┐
        │   GOLD LAYER (ANALYTICS)      │
        │   - Business views            │
        │   - Aggregated metrics        │
        │   - Executive dashboards      │
        └───────────────────────────────┘
```

### Schema Layers

| Layer      | Purpose                                | Design Pattern                   | Key Components                                            |
| ---------- | -------------------------------------- | -------------------------------- | --------------------------------------------------------- |
| **Bronze** | Raw data ingestion from source systems | Staging tables with SCD metadata | `stg_users`, `stg_trades`, `stg_holdings`, `stg_accounts` |
| **Silver** | Data transformation & conformation     | Star schema (Dimensions + Facts) | `dim_users`, `dim_assets`, `fact_trades`, `fact_holdings` |
| **Gold**   | Business analytics & reporting         | Aggregate views & cubes          | `rpt_trading_performance`, `rpt_investor_behavior`        |

---

## 🔄 Slowly Changing Dimensions (SCD Type 2)

This warehouse implements **SCD Type 2** to preserve the complete history of dimensional changes:

### Implementation Details

**Tracking Columns** (added to all dimensional tables):

```
valid_from    → Timestamp when the record became active
valid_to      → Timestamp when the record expired (NULL = current)
is_current    → Flag indicating active record (1 = current, 0 = historical)
```

**Example: User Dimension Evolution**

```
Bronze Layer (Staging):
- stg_users: user_id, username, email, status, valid_from, is_current, extraction_date

Silver Layer (Conformed):
- dim_users (SCD2): user_key (surrogate), user_id, username, email, status,
                    valid_from, valid_to, is_current

Benefits:
✓ Understand "what changed" about users over time
✓ Analyze metrics in historical context (point-in-time queries)
✓ Track regulatory compliance requirements (KYC status changes)
✓ Support audit trails and versioning
```

---

## 📂 Directory Structure & File Descriptions

### Create_Database/ (Schema & Infrastructure)

```
Create_Database/
├── DataBase_Main.sql          ► Core OLTP schema definition
│                               • Users, Accounts, Trading_Pairs tables
│                               • Broker application domain model
│                               • 50+ source tables for users, assets, trades
│
├── User_Schemas.sql            ► Create warehouse schemas
│                               • dw_bronze, dw_silver, dw_gold schemas
│                               • Role-based access control
│
├── Constraints.sql             ► Data quality enforcement
│                               • Primary Key, Foreign Key constraints
│                               • Check constraints for valid values
│                               • NOT NULL enforcement
│
├── Indexing.sql                ► Query performance optimization
│                               • Composite indexes on fact table lookup keys
│                               • Indexes on SCD tracking columns
│                               • Bitmap indexes on low-cardinality columns
│
├── Mock_DataAll.sql            ► Test data generation
│                               • INSERT statements with realistic data
│                               • Multiple user tiers and asset types
│                               • Sample trades and portfolio data
│
├── Stored_Procedure.sql        ► Business logic & orchestration
│                               • SCD merge procedures
│                               • Data validation routines
│
└── Droptable.sql               ► Cleanup & reset
```

### ETL/ (Extraction & Load)

```
ETL/
├── ETL_Stage_Bronze.sql        ► Bronze layer ingestion
│                               • EXTRACT phase of ETL
│                               • Loads OLTP source → Bronze staging
│                               • Adds extraction_date for audit trail
│                               • Sets is_current=1, valid_from=NOW()
│
├── DropBronze.sql              ► Bronze cleanup
│                               • Removes staging tables for reload
│
└── ETL_Clean_SilverUpdate.sql  ► Silver layer transformation
                                • TRANSFORM & LOAD phase
                                • Implements SCD Type 2 logic
                                • Data validation & cleansing
                                • Surrogate key generation
                                • Derives business metrics
```

### DataWH/ (Data Warehouse Layers)

```
DataWH/
├── Bronze.sql                  ► Bronze table definitions
│                               • Staging tables with identical source structure
│                               • SCD Type 2 audit columns added
│                               • Example: stg_users, stg_trades, stg_holdings
│
├── Silver.sql                  ► Conformed dimension & fact tables
│                               DIMENSIONS:
│                               • dim_users (SCD2): User master with history
│                               • dim_assets: Asset catalog
│                               • dim_trading_pairs: Cryptocurrency pairs
│                               • dim_portfolios: Account portfolio snapshot
│
│                               FACTS:
│                               • fact_trades: Trading transactions (grain: trade)
│                               • fact_holdings: Portfolio positions (grain: account-asset)
│
│                               ANALYTICS:
│                               • ana_user_behavior: Derived metrics
│
├── Gold.sql                    ► Business views & aggregates
│                               • rpt_trading_performance: Daily volume & fees
│                               • rpt_asset_holdings_by_tier: Wealth distribution
│                               • rpt_investor_behavior: Customer segmentation
│
└── ViewDataWarehouse.txt       ► Data dictionary & documentation
```

---

## 🚀 ETL Pipeline Execution Guide

### Prerequisites

- Oracle Database 19c+ or 21c
- SQL\*Plus or SQL Developer
- Proper DBA permissions for schema creation

### Step-by-Step Execution Order

**Phase 1: Foundation (OLTP Source)**

```sql
SQL> @Create_Database/DataBase_Main.sql
-- Creates broker application tables (Users, Trades, Accounts, etc.)
-- Total tables: ~15 source entities
```

**Phase 2: Infrastructure Setup**

```sql
SQL> @Create_Database/User_Schemas.sql
-- Creates dw_bronze, dw_silver, dw_gold schemas
-- Sets up warehouse users with appropriate privileges

SQL> @Create_Database/Constraints.sql
-- Enforces referential integrity & data validation rules

SQL> @Create_Database/Indexing.sql
-- Adds performance-critical indexes for query optimization
```

**Phase 3: Test Data Population**

```sql
SQL> @Create_Database/Mock_DataAll.sql
-- Loads representative sample data (~1000 users, ~50000 trades)
-- Used for ETL validation and testing
```

**Phase 4: Bronze Layer (Staging)**

```sql
SQL> @DataWH/Bronze.sql
-- Creates staging tables with SCD Type 2 metadata columns

SQL> @ETL/ETL_Stage_Bronze.sql
-- EXTRACT: Loads raw data from source → Bronze staging
-- Marks all records as current (is_current=1)
-- Records extraction timestamp for audit trail
```

**Phase 5: Silver Layer (Conformed Data)**

```sql
SQL> @DataWH/Silver.sql
-- Creates dimensional and fact tables with star schema

SQL> @ETL/ETL_Clean_SilverUpdate.sql
-- TRANSFORM & LOAD:
--   • Implements SCD Type 2 for changing dimensions
--   • Validates data quality
--   • Generates surrogate keys
--   • Derives business metrics (avg_trade_value, account_age_days)
--   • Handles slowly changing user attributes
```

**Phase 6: Gold Layer (Analytics)**

```sql
SQL> @DataWH/Gold.sql
-- Creates business views for reporting & dashboards
-- Views include:
--   • Trading performance (volume, revenue, fees)
--   • Asset distribution (by portfolio tier)
--   • Investor behavior (segmentation, loyalty)
```

**Optional: Reset Environment**

```sql
SQL> @Create_Database/Droptable.sql
-- Removes all objects for fresh start
-- Used for testing or recreating schema
```

---

## 🔍 Key Data Engineering Features

### 1. SCD Type 2 Implementation

```sql
-- Example: User status change tracking
-- When a user's KYC status changes from PENDING → VERIFIED:

-- Bronze (Raw):
INSERT INTO stg_users VALUES (100001, 'john_doe', 'john@example.com', 'PENDING', SYSDATE, 1, SYSDATE);

-- Silver (Processed):
-- Record 1 (Historical):
INSERT INTO dim_users VALUES (1, 100001, 'john_doe', 'john@example.com', 'PENDING',
                             TO_DATE('2024-01-15'), TO_DATE('2024-03-01'), 0);
-- Record 2 (Current):
INSERT INTO dim_users VALUES (2, 100001, 'john_doe', 'john@example.com', 'VERIFIED',
                             TO_DATE('2024-03-01'), NULL, 1);
```

**Analytical Benefits:**

- Query user status at any point in time: `WHERE valid_from <= date_of_interest AND (valid_to > date_of_interest OR is_current=1)`
- Analyze KYC completion rates by cohort
- Track average time-to-verification by user segment

### 2. Star Schema Design

**Fact Table: `fact_trades`** (Grain: One row per trade transaction)

```
Dimensions:
  - pair_id → dim_trading_pairs
  - (Denormalized) base_asset_id → dim_assets

Measures:
  - quantity (volume traded)
  - total_value (THB value)
  - fee_amount (revenue)
```

**Dimension Table: `dim_users` (SCD2)**

```
Attributes:
  - user_id (business key)
  - username, email (slowly changing)
  - two_factor_enabled (attribute)

Tracking:
  - valid_from, valid_to (time dimension)
  - is_current (current flag)
```

### 3. Data Quality & Validation

- **Constraints**: PK, FK, CHECK constraints ensure referential integrity
- **Audit Trail**: extraction_date on all records tracks load cycles
- **Idempotent Loads**: SCD logic prevents duplicates in re-runs
- **Null Handling**: NOT NULL constraints enforce completeness

### 4. Performance Optimization

- **Composite Indexes**: On fact table join keys (pair_id, account_id)
- **Bitmap Indexes**: On low-cardinality dimension columns (status, is_current)
- **Statistics**: Index usage optimizes query plans for aggregations

---

## 📊 Sample Analytics

### View: Trading Performance Report

```sql
rpt_trading_performance
├── Dimensions: trade_date, asset_type, trading_pair
├── Metrics:
│   ├── total_trades (count)
│   ├── total_volume_assets
│   ├── total_trading_value_thb
│   └── total_fee_revenue_thb
└── Use Case: Daily revenue dashboard, trading activity trends
```

### View: Investor Behavior Segmentation

```sql
rpt_investor_behavior
├── Dimensions: account_status, security_level, customer_loyalty_segment
├── Segments:
│   ├── New (<1 Month)
│   ├── Growing (1-3 Months)
│   └── Loyal (>3 Months)
├── Metrics: total_users, avg_trades_per_user, avg_order_size_thb
└── Use Case: Customer retention analysis, risk profiling
```

---

## 🛠️ Data Engineering Best Practices Demonstrated

| Practice                  | Implementation                            | Location                        |
| ------------------------- | ----------------------------------------- | ------------------------------- |
| **Schema Segregation**    | Separate OLTP/OLAP schemas                | dw_bronze, dw_silver, dw_gold   |
| **Idempotent Loading**    | SCD merge logic prevents re-inserts       | ETL_Clean_SilverUpdate.sql      |
| **Audit Trails**          | extraction_date + valid_from/to           | All Bronze tables + SCD columns |
| **Surrogate Keys**        | IDENTITY sequences for dimensions         | dim_users.user_key              |
| **Dimensional Integrity** | Historical tracking with SCD Type 2       | dim_users, dim_portfolios       |
| **Conformed Dimensions**  | Single source of truth for dimensions     | Silver schema                   |
| **Fact Normalization**    | Proper grain definition & degenerate dims | fact_trades, fact_holdings      |
| **Performance Tuning**    | Strategic indexing on join/filter columns | Indexing.sql                    |

---

### Data Lineage

```
Source System (broker_app)
    ↓ [Extract]
Bronze (dw_bronze)
    • stg_users, stg_trades, stg_holdings
    ↓ [Transform + Load with SCD2]
Silver (dw_silver)
    • dim_users (SCD2), dim_assets, fact_trades
    ↓ [Aggregate + Conform]
Gold (dw_gold)
    • rpt_trading_performance
    • rpt_asset_holdings_by_tier
    • rpt_investor_behavior
```

---

## 🔐 Data Governance & Quality Framework

### Extraction Audit

```
Column: extraction_date (TIMESTAMP)
Purpose: Track when each batch was loaded
Benefits:
  - Enables point-in-time queries
  - Facilitates restatement capability
  - Validates data freshness
```

### SCD Type 2 Audit

```
Columns: valid_from, valid_to, is_current
Purpose: Complete historical record management
Benefits:
  - Aggregate revenue by KYC status at historical dates
  - Analyze adoption of 2FA over time
  - Calculate metric changes between snapshots
```

### Referential Integrity

```
Constraints implemented:
  - PK on all dimension tables (user_id, asset_id, pair_id)
  - FK from facts to dimensions (pair_id → dim_trading_pairs)
  - Check constraints on status fields (PENDING|VERIFIED|ACTIVE)
  - NOT NULL on all business keys
```

---

## 📋 Entity-Relationship: Key Dimensional Model

### Dimension Entities

- **dim_users** (SCD2): User master with KYC history
- **dim_assets**: Cryptocurrency/asset catalog
- **dim_trading_pairs**: Trading pair configurations
- **dim_portfolios** (SCD2): Account portfolio snapshots

### Fact Entities

- **fact_trades** (Grain: Trade Transaction)
  - Links: dim_trading_pairs, dim_assets
  - Measures: quantity, price, fee_amount
  - Conformed: trade_time (TIMESTAMP)

- **fact_holdings** (Grain: Account-Asset position)
  - Links: dim_assets, dim_portfolios
  - Measures: quantity, available_qty, locked_qty
  - Snapshot date: extraction_date

### Analytical Mart

- **ana_user_behavior**: Pre-computed user metrics
  - account_age_days
  - trade_frequency_count
  - avg_trade_value

---

## 💾 Technology Stack

| Component             | Technology              | Version         |
| --------------------- | ----------------------- | --------------- |
| **Database**          | Oracle Database         | 19c+            |
| **SQL Layer**         | Oracle SQL              | Standard        |
| **Procedural**        | PL/SQL                  | Oracle Native   |
| **Schema Management** | DDL/DML                 | Oracle Standard |
| **Performance**       | B-Tree & Bitmap Indexes | Native          |
| **Audit**             | Timestamps & SCD        | Generic         |

---

## 📚 Use Cases & Applications

### 1. **Trading Performance Analytics**

```
Query: "What was total trading volume and revenue by asset type last month?"
Uses: rpt_trading_performance view + historical fact tables
SCD Benefit: N/A (facts don't change)
```

### 2. **Wealth Concentration Analysis**

```
Query: "What percentage of assets are held by Tier-1 users?"
Uses: dim_portfolios (SCD2) + fact_holdings + asset data
SCD Benefit: Track portfolio tier changes over time
```

### 3. **Customer Lifetime Value (CLV)**

```
Query: "What is CLV for users who were active 6 months ago?"
Uses: dim_users (with valid_to filtering) + trade history
SCD Benefit: Point-in-time historical queries on user dimensions
```

### 4. **Regulatory Compliance Reporting**

```
Query: "Show KYC verification timeline for all users"
Uses: dim_users SCD2 with valid_from/valid_to dates
SCD Benefit: Complete audit trail of KYC status transitions
```

### 5. **Cohort Analysis**

```
Query: "Compare 2FA adoption rate between users registered in Q1 vs Q2"
Uses: dim_users (cohort by registration_date) + two_factor_enabled SCD history
SCD Benefit: Track feature adoption patterns by user cohort
```

---

## 🔍 Query Examples

### Example 1: Current User Status

```sql
-- Get all active users with KYC verified
SELECT u.user_id, u.username, u.email, u.status, u.valid_from
FROM dw_silver.dim_users u
WHERE u.is_current = 1
  AND u.status = 'VERIFIED';
```

### Example 2: Historical User Status

```sql
-- Get user's KYC timeline
SELECT u.user_id, u.status, u.valid_from, u.valid_to
FROM dw_silver.dim_users u
WHERE u.user_id = 12345
ORDER BY u.valid_from;
```

### Example 3: Trading Performance by Tier

```sql
-- Daily trading volume by portfolio tier
SELECT
  TRUNC(t.trade_time) AS trade_date,
  p.portfolio_tier,
  SUM(t.quantity) AS total_volume,
  SUM(t.total_value) AS total_value_thb,
  SUM(t.fee_amount) AS fee_revenue_thb
FROM dw_silver.fact_trades t
JOIN dw_silver.dim_trading_pairs tp ON t.pair_id = tp.pair_id
JOIN dw_silver.dim_portfolios p ON tp.pair_id = p.account_id
WHERE TRUNC(t.trade_time) >= TRUNC(SYSDATE - 30)
GROUP BY TRUNC(t.trade_time), p.portfolio_tier;
```

### Example 4: Point-in-Time User Analysis

```sql
-- Recreate user dimension as it was on 2024-02-01
SELECT u.user_id, u.username, u.two_factor_enabled, u.status, 'as of 2024-02-01' AS snapshot_date
FROM dw_silver.dim_users u
WHERE u.valid_from <= TO_DATE('2024-02-01')
  AND (u.valid_to > TO_DATE('2024-02-01') OR u.is_current = 1);
```

---

## ✅ Testing & Validation

### Data Quality Checks

```sql
-- Check for orphaned fact records
SELECT COUNT(*) FROM dw_silver.fact_trades t
WHERE NOT EXISTS (SELECT 1 FROM dw_silver.dim_trading_pairs p WHERE p.pair_id = t.pair_id);

-- Validate SCD integrity (no overlapping valid dates)
SELECT user_key, username, count(*)
FROM dw_silver.dim_users
WHERE is_current = 1
GROUP BY user_key, username
HAVING count(*) > 1;

-- Check extraction date recency
SELECT MAX(extraction_date) AS latest_load, COUNT(*) AS record_count
FROM dw_silver.fact_trades;
```

---
