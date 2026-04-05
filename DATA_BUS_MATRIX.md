# Data Bus Matrix & Lineage (ตารางความเชื่อมโยงข้อมูล)
*เอกสารแสดงการไหลของข้อมูลจาก Source System ไปยัง Data Warehouse Reports*

---

## 1. Matrix สรุปการใช้ข้อมูล (Report to Tables Mapping)

| รายงาน (Report Views) | Source Tables (broker_app) | DWH Fact Tables | DWH Dimension Tables |
| :--- | :--- | :--- | :--- |
| **R1: Trading Performance** | `Trades`, `Trading_Pairs`, `Assets` | `fct_trades` | `dim_trading_pairs`, `dim_assets` |
| **R2: Asset Holdings** | `Holdings`, `Portfolio`, `Assets` | `fact_holdings` | `dim_portfolios`, `dim_assets` |
| **R3: Investor Behavior** | `Users`, `Trades`, `Buy_Orders`, `Sell_Orders` | `ana_user_behavior` | `dim_users` |

---

## 2. รายละเอียดการดึงข้อมูลรายรายงาน (Data Requirement by Report)

### รายงานที่ 1: Trading Performance (ผลการดำเนินงาน)
*   **เป้าหมาย:** สรุปยอดเทรดและรายได้
*   **ตารางหลักที่ต้องการ (Fact):**
    *   `fct_trades`: แปลงมาจาก `broker_app.Trades` เพื่อเก็บราคาและปริมาณที่ Match กันจริง
*   **ตารางสนับสนุน (Dimension):**
    *   `dim_trading_pairs`: เพื่อระบุว่าเทรดคู่ไหน (เช่น BTC/THB)
    *   `dim_assets`: เพื่อระบุประเภทเหรียญ (Crypto/Fiat)

### รายงานที่ 2: Asset Holdings (การถือครองและความมั่งคั่ง)
*   **เป้าหมาย:** วิเคราะห์ยอดคงเหลือและระดับความรวย (Tiering)
*   **ตารางหลักที่ต้องการ (Fact):**
    *   `fact_holdings`: แปลงมาจาก `broker_app.Holdings` เพื่อเก็บยอดคงเหลือรายเหรียญของแต่ละคน
*   **ตารางสนับสนุน (Dimension):**
    *   `dim_portfolios`: แปลงมาจาก `broker_app.Portfolio` เพื่อแบ่งกลุ่มลูกค้า (Whale/Retail) ตามยอดเงินสด
    *   `dim_assets`: เพื่อแสดงสัญลักษณ์เหรียญ (Symbol)

### รายงานที่ 3: Investor Behavior (พฤติกรรมลูกค้า)
*   **เป้าหมาย:** วิเคราะห์ความถี่และคุณภาพลูกค้า
*   **ตารางหลักที่ต้องการ (Fact/Analysis):**
    *   `ana_user_behavior`: เป็นตารางคำนวณพิเศษ (Aggregated Table) ที่ดึงจาก `fct_trades` และประวัติการส่ง Order (`Buy/Sell Orders`) เพื่อหาค่าเฉลี่ยรายคน
*   **ตารางสนับสนุน (Dimension):**
    *   `dim_users`: แปลงมาจาก `broker_app.Users` เพื่อดูสถานะการเปิด 2FA และวันที่สมัครสมาชิก

---

## 3. ผังการไหลของข้อมูล (Conceptual Data Flow)

`[ Source: broker_app ]` --(ETL: dbt_run)--> `[ DWH: trading_dwh ]` --(Views)--> `[ Executive Reports ]`

1.  **Extract:** ดึงข้อมูลจากตาราง `Users`, `Trades`, `Holdings`, `Portfolio` มาพักไว้ที่ชั้น Staging
2.  **Transform:** ทำความสะอาดข้อมูล (Cleanse) และจัดโครงสร้างใหม่เป็น Fact/Dimension
3.  **Load:** นำข้อมูลเข้าตาราง `fct_`, `dim_`, และตารางวิเคราะห์ `ana_`
4.  **Visualize:** View ในชั้น Gold (Report Layer) ดึงข้อมูลจาก Fact/Dim มาแสดงผลในรูปแบบรายงาน
