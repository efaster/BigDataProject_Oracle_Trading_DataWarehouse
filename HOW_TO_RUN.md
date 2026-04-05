# 🚀 How to run this project (dbt-style DWH)

ลำดับการรันสคริปต์เพื่อติดตั้งและใช้งานระบบ Trading Data Warehouse (DWH) ตั้งแต่เริ่มต้นจนจบ โดยแบ่งตามสิทธิ์ผู้ใช้งาน (Roles)

---

## 🏗️ ส่วนที่ 1: การสร้างบ้านและโครงสร้าง (Admin Setup)
**ผู้รัน (User):** `SYSTEM` หรือ `SYS` (ฐานะ Admin)

1.  **`db/setup/01_user_schemas.sql`**: สร้าง User `broker_app` และ `trading_dwh` พร้อมให้สิทธิ์ที่จำเป็น

---

## 📱 ส่วนที่ 2: ระบบต้นทาง (Application Source)
**ผู้รัน (User):** `broker_app` (รหัสผ่าน: `AppPassword123#`)

2.  **`db/setup/02_database_main.sql`**: สร้างตารางหลักของแอปฯ (Users, Trades, Assets)
3.  **`db/setup/03_constraints.sql`**: ติดตั้งความสัมพันธ์ (Primary/Foreign Key)
4.  **`db/setup/04_indexing.sql`**: เพิ่มประสิทธิภาพการทำงาน (Index)
5.  **`db/setup/05_stored_procedures.sql`**: ติดตั้ง Logic การเทรด (Trade Matching)
6.  **`db/staging/mock_data.sql`**: เติมข้อมูลจำลองเริ่มต้น

---

## 📊 ส่วนที่ 3: ระบบวิเคราะห์ข้อมูล (Data Warehouse Modeling)
**ผู้รัน (User):** `trading_dwh` (รหัสผ่าน: `DwhPassword123#`)

7.  **`db/setup/06_functions.sql`**: สร้างฟังก์ชันคำนวณ (Business Logic)
8.  **`db/setup/07_etl_procedures.sql`**: ติดตั้งเครื่องยนต์ `dbt_run` และตาราง Log/Artifacts
9.  **`db/staging/stg_tables.sql`**: สร้างตารางพักข้อมูล (`STG_`)
10. **`db/dimensions/dim_tables.sql`**: สร้างตารางมิติ (`DIM_`)
11. **`db/facts/fact_tables.sql`**: สร้างตารางข้อเท็จจริง (`FCT_`)
12. **`db/marts/mart_views.sql`**: สร้างวิวรายงาน (`RPT_`)

---

## 🚀 ส่วนที่ 4: การรัน Pipeline และตรวจสอบ (Execution)
**ผู้รัน (User):** `trading_dwh`

*   **รัน Pipeline**: `EXEC dbt_run;` (ดึงข้อมูลใหม่และประมวลผลทันที)
*   **ตรวจสอบ Log**: `SELECT * FROM dbt_run_log ORDER BY started_at DESC;`
*   **ดูรายงาน**: `SELECT * FROM rpt_trading_performance;`

---

### 💡 หมายเหตุสำคัญ
*   **การแยก User**: ช่วยให้จำลองสถานการณ์จริงที่ระบบวิเคราะห์ (DWH) ไปดึงข้อมูลจากระบบแอปฯ (Source) ข้าม Schema ได้
*   **Incremental Load**: ระบบจะจำจุดที่ดึงล่าสุดไว้ในตาราง `dbt_artifacts` ไม่ต้องกังวลเรื่องข้อมูลซ้ำ
*   **Single User for DWH**: ทุกอย่างที่เป็นงานวิเคราะห์ถูกรวมไว้ภายใต้ `trading_dwh` เพื่อความสะดวกในการ Join ตาราง
