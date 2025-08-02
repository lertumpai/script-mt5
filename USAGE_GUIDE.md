# คู่มือการใช้งาน XGBoost Binary Option M1

## ไฟล์ที่สร้างขึ้น

### 1. Python Scripts
- `train_xgboost_model.py` - Script สำหรับเทรน XGBoost model
- `requirements.txt` - Dependencies สำหรับ Python

### 2. MQL5 Files
- `BinaryOptionXGBoost.mq5` - EA หลัก
- `BinaryOptionXGBoost_Complete.mq5` - EA ที่สมบูรณ์กว่า

### 3. Documentation
- `README.md` - คำอธิบายระบบ
- `USAGE_GUIDE.md` - คู่มือการใช้งาน

## ขั้นตอนการใช้งาน

### ขั้นตอนที่ 1: ติดตั้ง Python Environment
```bash
# ติดตั้ง dependencies
pip install pandas numpy xgboost scikit-learn joblib

# หรือใช้ requirements.txt
pip install -r requirements.txt
```

### ขั้นตอนที่ 2: เทรนโมเดล
```bash
python train_xgboost_model.py
```

### ขั้นตอนที่ 3: ใช้งานใน MetaTrader 5

1. **คัดลอกไฟล์ EA**
   - คัดลอก `BinaryOptionXGBoost_Complete.mq5` ไปยังโฟลเดอร์ `MQL5/Experts/`

2. **คอมไพล์ EA**
   - เปิด MetaEditor
   - เปิดไฟล์ `BinaryOptionXGBoost_Complete.mq5`
   - กด F7 เพื่อคอมไพล์

3. **เพิ่ม EA ลงในชาร์ต**
   - เปิดชาร์ต M1 ของคู่เงินที่ต้องการ
   - ลาก EA จาก Navigator ไปยังชาร์ต
   - ตั้งค่าพารามิเตอร์

## พารามิเตอร์ที่สำคัญ

| พารามิเตอร์ | ค่าเริ่มต้น | คำอธิบาย |
|------------|------------|----------|
| InpLookback | 20 | จำนวนแท่งเทียนที่ใช้คำนวณ features |
| InpLotSize | 0.1 | ขนาด Lot |
| InpMagic | 12345 | Magic Number |
| InpWinRateThreshold | 0.6 | เกณฑ์ Win Rate (60%) |
| InpEnableTrading | false | เปิดใช้งานการเทรนจริง |
| InpMaxOrders | 1 | จำนวน orders สูงสุด |
| InpShowDebug | true | แสดงข้อมูล debug |

## Features ที่ใช้ (21 features)

1. **Price-based (3 features)**
   - price_change: การเปลี่ยนแปลงราคา
   - high_low_ratio: อัตราส่วน high/low
   - close_open_ratio: อัตราส่วน close/open

2. **Moving Average (3 features)**
   - price_vs_ma5: ราคาเทียบกับ MA5
   - price_vs_ma10: ราคาเทียบกับ MA10
   - price_vs_ma20: ราคาเทียบกับ MA20

3. **Volatility (2 features)**
   - volatility_5: ความผันผวน 5 นาที
   - volatility_10: ความผันผวน 10 นาที

4. **RSI (2 features)**
   - rsi_5: RSI 5 นาที
   - rsi_10: RSI 10 นาที

5. **Momentum (2 features)**
   - momentum_3: แรงขับเคลื่อน 3 นาที
   - momentum_5: แรงขับเคลื่อน 5 นาที

6. **Volume (1 feature)**
   - volume_proxy: ปริมาณการซื้อขาย (proxy)

7. **Time (3 features)**
   - hour: ชั่วโมง
   - minute: นาที
   - day_of_week: วันในสัปดาห์

8. **Candle Patterns (3 features)**
   - body_size: ขนาดของแท่งเทียน
   - upper_shadow: เงาบน
   - lower_shadow: เงาล่าง

9. **Trend (2 features)**
   - trend_5: แนวโน้ม 5 นาที
   - trend_10: แนวโน้ม 10 นาที

## ระบบ XGBoost (50 ต้นไม้)

### ต้นไม้ที่ 1-10
- ใช้เงื่อนไขที่ซับซ้อน
- ตรวจสอบ features หลายตัว
- ให้ผลลัพธ์ที่แม่นยำ

### ต้นไม้ที่ 11-50
- ใช้เงื่อนไขแบบง่าย
- ตรวจสอบ features หลัก
- เพิ่มความหลากหลาย

## สัญญาณที่ส่ง

### CALL Signal
- เมื่อความน่าจะเป็น > 60%
- ราคาคาดว่าจะขึ้น
- ส่งสัญญาณซื้อ

### PUT Signal
- เมื่อความน่าจะเป็น ≤ 60%
- ราคาคาดว่าจะลง
- ส่งสัญญาณขาย

## การทดสอบ

### 1. ทดสอบใน Demo Account
- เปิด Demo Account
- ตั้งค่า `InpEnableTrading = false` ก่อน
- ดูสัญญาณที่ส่งใน Journal

### 2. ทดสอบการเทรนจริง
- ตั้งค่า `InpEnableTrading = true`
- เริ่มต้นด้วย Lot ขนาดเล็ก
- ตรวจสอบผลลัพธ์อย่างใกล้ชิด

## ข้อควรระวัง

1. **Risk Management**
   - ใช้ Lot ขนาดเล็ก
   - ตั้ง Stop Loss
   - ไม่เทรนเกินความสามารถ

2. **Market Conditions**
   - ระบบทำงานดีในตลาดที่มีแนวโน้ม
   - อาจไม่เหมาะกับตลาด Sideways

3. **Backtesting**
   - ทดสอบในข้อมูลย้อนหลัง
   - ตรวจสอบ Win Rate จริง
   - ปรับพารามิเตอร์ตามผลลัพธ์

## การปรับแต่ง

### ปรับ Win Rate Threshold
```mql5
input double InpWinRateThreshold = 0.6; // เปลี่ยนเป็น 0.7 สำหรับความแม่นยำสูงขึ้น
```

### ปรับจำนวน Features
```mql5
double g_features[21]; // เพิ่มหรือลดจำนวน features
```

### ปรับต้นไม้
```mql5
// เพิ่มต้นไม้ใหม่ใน PredictSignal()
prediction += PredictTree11();
```

## การแก้ไขปัญหา

### ปัญหาที่พบบ่อย

1. **EA ไม่ส่งสัญญาณ**
   - ตรวจสอบ timeframe (ต้องเป็น M1)
   - ตรวจสอบข้อมูลราคา
   - เปิด debug mode

2. **สัญญาณไม่แม่นยำ**
   - ปรับ Win Rate Threshold
   - เพิ่ม features
   - เทรนโมเดลใหม่

3. **Order ไม่ผ่าน**
   - ตรวจสอบ Market Hours
   - ตรวจสอบ Margin
   - ตรวจสอบ Broker Settings

## สรุป

ระบบ XGBoost Binary Option M1 นี้ใช้:
- **50 ต้นไม้** สำหรับการทำนาย
- **21 features** สำหรับการวิเคราะห์
- **Win Rate 60%** เป็นเป้าหมาย
- **M1 timeframe** สำหรับการเทรน

ระบบนี้เหมาะสำหรับการเทรน Binary Option ที่ต้องการความแม่นยำและความเร็วในการส่งสัญญาณ 