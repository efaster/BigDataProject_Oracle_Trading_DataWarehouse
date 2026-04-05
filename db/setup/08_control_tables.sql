/* =====================================================================
   Script Name: 08_control_tables.sql
   Description: ตารางควบคุมการไหลของข้อมูล (ETL Control & Watermarking)
   ===================================================================== */

-- สร้าง Schema สำหรับงานควบคุม (ถ้ายังไม่มี)
-- ในที่นี้ขอใช้ภายใต้ dw_bronze เพื่อความสะดวกในโปรเจกต์นี้
CREATE TABLE dw_bronze.etl_watermarks (
    table_name VARCHAR2(100) PRIMARY KEY,
    last_extraction_date TIMESTAMP,
    last_processed_id NUMBER
);

-- เตรียมค่าเริ่มต้นสำหรับ Watermarks
INSERT INTO dw_bronze.etl_watermarks (table_name, last_extraction_date, last_processed_id)
VALUES ('USERS', TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'), 0);

INSERT INTO dw_bronze.etl_watermarks (table_name, last_extraction_date, last_processed_id)
VALUES ('TRADES', TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'), 0);

COMMIT;
