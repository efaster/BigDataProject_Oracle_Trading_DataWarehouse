# รายงานเชิงบริหาร (Executive Reports Management - RM)
*อ้างอิงตามโครงสร้างตารางและ View จริงในระบบ Data Warehouse*

---

## รายงานเชิงบริหาร 1 : รายงานผลการดำเนินงานด้านการซื้อขาย (Trading Performance Report)
**วัตถุประสงค์:** เพื่อวิเคราะห์ปริมาณการซื้อขายและรายได้จากค่าธรรมเนียมในแต่ละช่วงเวลา
* **View ที่เกี่ยวข้อง:** `rpt_trading_performance`
* **รายละเอียดที่นำเสนอ:**
    * จำนวนรายการเทรดรวม (**Total Trades**)
    * ปริมาณเหรียญที่ซื้อขาย (**Total Volume Assets**)
    * มูลค่าการเทรดรวมเป็นเงินบาท (**Total Trading Value THB**)
    * รายได้ค่าธรรมเนียมรวม (**Total Fee Revenue THB**)
* **ข้อมูลที่ใช้ (Data Mapping):**
    * **Fact:** `fct_trades` (ข้อมูลการ Match Order)
    * **Dimension:** `dim_trading_pairs` (คู่เทรด), `dim_assets` (ประเภทสินทรัพย์)

---

## รายงานเชิงบริหาร 2 : รายงานการถือครองสินทรัพย์และความมั่งคั่ง (Asset Holdings & Wealth Concentration)
**วัตถุประสงค์:** เพื่อวิเคราะห์สัดส่วนการถือครองสินทรัพย์ตามกลุ่มขนาดพอร์ตลงทุน (Whale vs Retail)
* **View ที่เกี่ยวข้อง:** `rpt_asset_holdings_by_tier`
* **รายละเอียดที่นำเสนอ:**
    * การจัดกลุ่มนักลงทุนตามระดับพอร์ต (**Portfolio Tier**)
    * จำนวนผู้ถือครองแยกตามประเภทสินทรัพย์ (**Total Investors**)
    * ยอดคงเหลือของสินทรัพย์ (**Total Holding Balance**)
    * จำนวนสินทรัพย์ที่ถูกล็อกในคำสั่งซื้อขาย (**Total Locked in Orders**)
* **ข้อมูลที่ใช้ (Data Mapping):**
    * **Fact:** `fact_holdings` (ยอดคงเหลือรายเหรียญ), `dim_portfolios` (ข้อมูลระดับพอร์ต)
    * **Dimension:** `dim_assets` (สัญลักษณ์และประเภทเหรียญ)

---

## รายงานเชิงบริหาร 3 : รายงานวิเคราะห์พฤติกรรมการซื้อขายและคุณภาพลูกค้า (Investor Behavior & Customer Quality)
**วัตถุประสงค์:** เพื่อวิเคราะห์คุณภาพของลูกค้าและความภักดี (Loyalty) ต่อแพลตฟอร์ม
* **View ที่เกี่ยวข้อง:** `rpt_investor_behavior`
* **รายละเอียดที่นำเสนอ:**
    * สถานะบัญชีลูกค้า (**Account Status**) และระดับความปลอดภัย (**Security Level**)
    * การแบ่งกลุ่มลูกค้าตามอายุการใช้งาน (**Customer Loyalty Segment**)
    * สถิติการเทรดเฉลี่ยต่อคน (**Avg Trades per User**) และมูลค่าเฉลี่ยต่อไม้ (**Avg Order Size**)
* **ข้อมูลที่ใช้ (Data Mapping):**
    * **Fact/Analysis Table:** `ana_user_behavior` (ตารางสรุปพฤติกรรมราย User)
    * **Dimension:** `dim_users` (ข้อมูลพื้นฐานและสถานะปัจจุบันของ User)

---

### หมายเหตุทางเทคนิค (Technical Notes):
1. **การรวมข้อมูล:** ข้อมูล Fact จะถูกดึงมาจากกระบวนการ ETL ที่ทำความสะอาดข้อมูลแล้ว
2. **ความสอดคล้อง:** รายงานทั้ง 3 ฉบับถูกออกแบบมาให้เชื่อมโยงกันผ่าน `user_id` และ `asset_id` เพื่อให้นักวิเคราะห์สามารถเจาะลึก (Drill-down) ข้อมูลจากภาพรวมไปยังพฤติกรรมรายบุคคลได้
3. **สถานะตาราง:** หากตาราง `fact_holdings` หรือ `ana_user_behavior` ยังไม่มีข้อมูลในระบบ จะต้องรัน Procedure `dbt_run` เพื่อทำการ Transform ข้อมูลก่อน
