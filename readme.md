# 🏗️ Oracle Data Warehouse - Trading Platform | Medallion Architecture

A comprehensive **enterprise data warehouse (EDW)** and **ETL pipeline** built with **Oracle SQL & PL/SQL**, designed for a trading/brokerage platform. This project follows the **Medallion Architecture** (Bronze → Silver → Gold) to demonstrate production-grade data engineering practices.

---

## 📌 Project Overview

This solution transforms raw transactional data from a broker application into an analytical data warehouse. The architecture is organized into clear layers to ensure data quality, historical traceability, and analytical readiness.

**Key Engineering Features:**
- ✅ **Medallion Architecture** - Structured data flow from Staging to Analytics
- ✅ **SCD Type 2 Implementation** - Historical tracking for dimensions
- ✅ **Star Schema Design** - Optimized for OLAP queries and reporting
- ✅ **Multi-layer ETL Pipeline** - Segregated Extract, Transform, and Load logic
- ✅ **Data Quality & Performance** - Enterprise-grade constraints and strategic indexing

---

## 🏛️ Data Architecture (Medallion Pattern)

```
                    OLTP Source (Broker App)
                        ↓
        ┌──────────────────────────────────────────┐
        │   📁 db/staging (BRONZE LAYER)           │
        │   - Raw data ingestion from source       │
        │   - Technical metadata (extraction_date) │
        └──────────────────────────────────────────┘
                        ↓
        ┌──────────────────────────────────────────┐
        │   📁 db/dimensions & db/facts (SILVER)   │
        │   - Data cleaning & Conformation         │
        │   - Slowly Changing Dimensions (SCD2)    │
        │   - Fact tables (Trades, Holdings)       │
        └──────────────────────────────────────────┘
                        ↓
        ┌──────────────────────────────────────────┐
        │   📁 db/marts (GOLD LAYER)               │
        │   - Business-ready views                 │
        │   - Executive dashboard logic            │
        └──────────────────────────────────────────┘
```

---

## 📂 Directory Structure

### 📁 `db/` - Database Layer (SQL)
Organized by the Medallion Architecture layers for storage and schema definition.

*   **`setup/`**: Infrastructure and core database setup.
    *   `01_user_schemas.sql`: Creates `dw_bronze`, `dw_silver`, and `dw_gold` users.
    *   `02_database_main.sql`: Core OLTP schema (Broker App source tables).
    *   `03_constraints.sql`: Data integrity rules (PK, FK, Checks).
    *   `04_indexing.sql`: Performance optimization (B-tree, Bitmaps).
    *   `05_stored_procedures.sql`: Orchestration and business logic.
    *   `cleanup.sql`: Utility script to reset the database.
*   **`staging/` (Bronze)**: Staging area for raw data.
    *   `stg_tables.sql`: Definitions for raw staging tables.
    *   `mock_data.sql`: Realistic test data for simulation.
    *   `stg_cleanup.sql`: Script to purge staging data.
*   **`dimensions/` (Silver)**: Conformed dimension tables.
    *   `dim_tables.sql`: Definitions for `dim_users` (SCD2), `dim_assets`, etc.
*   **`facts/` (Silver)**: Business event fact tables.
    *   `fact_tables.sql`: Definitions for `fact_trades` and `fact_holdings`.
*   **`marts/` (Gold)**: Aggregated data for analytics.
    *   `mart_views.sql`: Analytical views (Trading Performance, Behavior).

### 📁 `etl/` - Data Pipeline Layer
Segregated by the functional steps of the ETL process.

*   **`extract/`**: Data movement from Source to Bronze.
    *   `extract_bronze.sql`: Pulls data from `broker_app` to `dw_bronze`.
*   **`transform/`**: Logic for data cleaning and Silver layer processing.
    *   `transform_silver.sql`: Implements SCD Type 2 logic and business transformations.
*   **`load/`**: Final loading logic into Silver/Gold (Currently handled within transform scripts).
*   **`dags/`**: Placeholder for workflow orchestration (e.g., Apache Airflow).

---

## 🔄 ETL Pipeline Execution Guide

### Prerequisites
- Oracle Database 19c+ or 21c
- DBA-level permissions for schema creation

### Step-by-Step Setup

1.  **Initialize Infrastructure**
    ```sql
    SQL> @db/setup/01_user_schemas.sql
    SQL> @db/setup/02_database_main.sql
    SQL> @db/setup/03_constraints.sql
    SQL> @db/setup/04_indexing.sql
    ```

2.  **Prepare Staging & Test Data**
    ```sql
    SQL> @db/staging/stg_tables.sql
    SQL> @db/staging/mock_data.sql
    ```

3.  **Deploy Warehouse Schema (Silver/Gold)**
    ```sql
    SQL> @db/dimensions/dim_tables.sql
    SQL> @db/facts/fact_tables.sql
    SQL> @db/marts/mart_views.sql
    ```

4.  **Run ETL Process**
    ```sql
    -- Phase 1: Extract (Source -> Bronze)
    SQL> @etl/extract/extract_bronze.sql

    -- Phase 2: Transform & Load (Bronze -> Silver)
    SQL> @etl/transform/transform_silver.sql
    ```

---

## 🔍 Key Data Engineering Concepts Demonstrated

### Slowly Changing Dimensions (SCD Type 2)
Preserves historical accuracy by tracking changes over time using:
- `valid_from` / `valid_to`: Time range of record validity.
- `is_current`: Flag for the active version.

### Star Schema Design
Optimized for high-performance analytics:
- **Facts**: `fact_trades` (Transactions), `fact_holdings` (Snapshots).
- **Dimensions**: `dim_users`, `dim_assets`, `dim_trading_pairs`.

### Analytical Views (Gold Layer)
- **`rpt_trading_performance`**: Daily volume, revenue, and fee analysis.
- **`rpt_investor_behavior`**: Customer segmentation and loyalty metrics.

---

## 💾 Technology Stack
- **Database**: Oracle Database 19c/21c
- **Language**: Oracle SQL & PL/SQL
- **Architecture**: Medallion Pattern, Star Schema
- **History Tracking**: SCD Type 2
