# XGBoost Binary Option M1 Model

ระบบเทรน XGBoost สำหรับ Binary Option M1 ที่อ่านข้อมูลจาก CSV และสร้างสัญญาณ CALL/PUT

## คุณสมบัติ

- เทรน XGBoost model ด้วย 50 ต้นไม้
- เป้าหมาย Win Rate 60%
- สร้างโค้ด MQL5 สำหรับใช้งานใน MetaTrader 5
- ใช้ Technical Indicators 21 features

## การติดตั้ง

1. ติดตั้ง Python dependencies:
```bash
pip install -r requirements.txt
```

2. รันการเทรนโมเดล:
```bash
python train_xgboost_model.py
```

## Features ที่ใช้

1. **Price-based features:**
   - price_change: การเปลี่ยนแปลงราคา
   - high_low_ratio: อัตราส่วน high/low
   - close_open_ratio: อัตราส่วน close/open

2. **Moving Average features:**
   - price_vs_ma5: ราคาเทียบกับ MA5
   - price_vs_ma10: ราคาเทียบกับ MA10
   - price_vs_ma20: ราคาเทียบกับ MA20

3. **Volatility features:**
   - volatility_5: ความผันผวน 5 นาที
   - volatility_10: ความผันผวน 10 นาที

4. **RSI features:**
   - rsi_5: RSI 5 นาที
   - rsi_10: RSI 10 นาที

5. **Momentum features:**
   - momentum_3: แรงขับเคลื่อน 3 นาที
   - momentum_5: แรงขับเคลื่อน 5 นาที

6. **Time features:**
   - hour: ชั่วโมง
   - minute: นาที
   - day_of_week: วันในสัปดาห์

7. **Candle patterns:**
   - body_size: ขนาดของแท่งเทียน
   - upper_shadow: เงาบน
   - lower_shadow: เงาล่าง

8. **Trend features:**
   - trend_5: แนวโน้ม 5 นาที
   - trend_10: แนวโน้ม 10 นาที

## ไฟล์ที่สร้าง

1. **binary_option_xgboost_model.pkl** - โมเดล XGBoost ที่เทรนแล้ว
2. **BinaryOptionXGBoost.mq5** - Expert Advisor สำหรับ MetaTrader 5

## การใช้งานใน MetaTrader 5

1. คัดลอกไฟล์ `BinaryOptionXGBoost.mq5` ไปยังโฟลเดอร์ `MQL5/Experts/`
2. คอมไพล์ EA ใน MetaEditor
3. เพิ่ม EA ลงในชาร์ต M1
4. ตั้งค่าพารามิเตอร์ตามต้องการ

## พารามิเตอร์

- **InpLookback**: จำนวนแท่งเทียนที่ใช้คำนวณ features (ค่าเริ่มต้น: 20)
- **InpLotSize**: ขนาด Lot (ค่าเริ่มต้น: 0.1)
- **InpMagic**: Magic Number (ค่าเริ่มต้น: 12345)
- **InpExpirationMinutes**: เวลาหมดอายุ Binary Option (ค่าเริ่มต้น: 5)

## สัญญาณ

- **CALL**: เมื่อความน่าจะเป็น > 60%
- **PUT**: เมื่อความน่าจะเป็น ≤ 60%

## หมายเหตุ

- ระบบนี้ใช้ข้อมูลราคา EURUSD M1
- ควรทดสอบใน Demo Account ก่อนใช้งานจริง
- ผลการเทรนอาจแตกต่างกันตามข้อมูลและตลาด 