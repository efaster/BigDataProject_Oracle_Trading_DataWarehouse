# 📊 Oracle Trading Data Warehouse (dbt-style)

โปรเจกต์นี้คือระบบ Data Warehouse สำหรับข้อมูลการเทรด โดยใช้สถาปัตยกรรมแบบ **Single User** และใช้แนวทางการตั้งชื่อ (Naming Convention) ตามแบบ **dbt** เพื่อความคล่องตัวในการพัฒนาและจัดการข้อมูล

---

## 🏗️ โครงสร้างเลเยอร์ข้อมูล (Data Layers)

ระบบใช้ Prefix นำหน้าชื่อตารางเพื่อแบ่ง Layer ภายใต้ User เดียวกัน:
1.  **`STG_` (Staging)**: ข้อมูลดิบที่ดึงมาจาก Source System (Extract) ยังไม่มีการแก้ไข Logic
2.  **`DIM_` / `FCT_` (Marts)**: ข้อมูลที่ผ่านการ Transform และจัดระเบียบเป็น Star Schema (Dimensions & Facts)
3.  **`RPT_` (Reporting)**: Views สำหรับดึงไปทำ Dashboard หรือรายงานสรุปผล (Gold Layer)

---

## 📁 โครงสร้างโฟลเดอร์ (Folder Structure)

*   `db/setup/`: สคริปต์สำหรับติดตั้งระบบ (User, Functions, Stored Procedures, Control Tables)
*   `db/staging/`: การนิยามตารางพักข้อมูล (`stg_`)
*   `db/dimensions/`: ตารางมิติ (`dim_`) เช่น ข้อมูลลูกค้า, สินทรัพย์
*   `db/facts/`: ตารางข้อเท็จจริง (`fct_`) เช่น รายการเทรด, ยอดคงเหลือ
*   `db/marts/`: วิวสำหรับรายงาน (`rpt_`)

---

## 🚀 ขั้นตอนการติดตั้งและรันระบบ (Step-by-Step)

### 1. การเตรียมระบบ (Setup Phase)
รันสคริปต์ในโฟลเดอร์ `db/setup/` ตามลำดับ:
1.  `01_user_schemas.sql`: สร้าง User `TRADING_DWH` และให้สิทธิ์ที่จำเป็น
2.  `06_functions.sql`: สร้างฟังก์ชันช่วยคำนวณ (Business Logic)
3.  `07_etl_procedures.sql`: สร้างตาราง Log/Artifacts และหัวใจหลักคือ Procedure `dbt_run`

### 2. การสร้างโครงสร้างข้อมูล (Modeling Phase)
รันสคริปต์เพื่อสร้างตาราง (Run once):
1.  `db/staging/stg_tables.sql`
2.  `db/dimensions/dim_tables.sql`
3.  `db/facts/fact_tables.sql`
4.  `db/marts/mart_views.sql`

### 3. การรัน Pipeline (Execution Phase)
เมื่อต้องการอัปเดตข้อมูลจากระบบ App เข้าสู่ Data Warehouse ให้ใช้คำสั่งเดียว:
```sql
EXEC dbt_run;
```

---

## 🔍 การตรวจสอบและติดตามผล (Monitoring)

*   **ตรวจสอบสถานะการรัน**: ดูประวัติการทำงานและ Error ย้อนหลัง
    ```sql
    SELECT * FROM dbt_run_log ORDER BY started_at DESC;
    ```
*   **ตรวจสอบจุดดึงข้อมูลล่าสุด (Watermark)**: ดูว่าระบบดึงข้อมูลถึง ID ไหนแล้ว
    ```sql
    SELECT * FROM dbt_artifacts;
    ```
*   **ดูรายงานสรุปผล**:
    ```sql
    SELECT * FROM rpt_trading_performance;
    ```

---

## 💡 จุดเด่นของระบบนี้
*   **Single User**: จัดการง่าย ไม่ซับซ้อนเรื่อง Permissions ระหว่าง Schema
*   **Incremental Load**: ดึงเฉพาะข้อมูลใหม่มาต่อท้าย (Append-only in Staging) โดยใช้ระบบ Watermarking
*   **Audit Trail**: มี Log เก็บทุกขั้นตอนการรัน สอดคล้องกับมาตรฐาน Data Engineering จริง
