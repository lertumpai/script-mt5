# Binary Option ML Trading System

ระบบ Machine Learning สำหรับเทรด Binary Option ที่พัฒนาด้วย Python และ MQL5

## ผลการทดสอบโมเดล

### โมเดลที่ 1: RandomForest
- **Win Rate**: 56.68%
- **Accuracy**: 56.68%
- **Features**: 17 technical indicators

### โมเดลที่ 2: ExtraTrees (Enhanced)
- **Win Rate**: 54.37%
- **Accuracy**: 54.37%
- **AUC**: 56.64%
- **Features**: 14 enhanced technical indicators

### โมเดลที่ 3: GradientBoosting
- **Win Rate**: 52.58%
- **Accuracy**: 52.58%

### โมเดลที่ 4: LogisticRegression
- **Win Rate**: 51.38%
- **Accuracy**: 51.38%

## โครงสร้างไฟล์

```
script-mt5/
├── ohlc.csv                          # ข้อมูล OHLC (218,475 แถว)
├── ml_models.py                      # โมเดล ML แบบพื้นฐาน
├── enhanced_ml_models.py             # โมเดล ML แบบปรับปรุง
├── requirements.txt                  # Python dependencies
├── BinaryOptionML_EA.mq5            # MQL5 Expert Advisor
├── enhanced_extratrees_library.mqh   # MQL5 Library (โมเดลที่ดีที่สุด)
├── randomforest_model.mq5           # MQL5 Model (โมเดลแรก)
├── *.pkl                            # Saved Python models
└── README.md                        # ไฟล์นี้
```

## วิธีการใช้งาน

### 1. ติดตั้ง Dependencies

```bash
pip install -r requirements.txt
```

### 2. รันการเทรนโมเดล

#### โมเดลพื้นฐาน:
```bash
python ml_models.py
```

#### โมเดลปรับปรุง:
```bash
python enhanced_ml_models.py
```

### 3. ใช้งานใน MetaTrader 5

1. คัดลอกไฟล์ต่อไปนี้ไปยัง MetaTrader 5:
   - `BinaryOptionML_EA.mq5`
   - `enhanced_extratrees_library.mqh`

2. เปิด MetaTrader 5 และไปที่:
   - **File** → **Open Data Folder**
   - ไปที่ `MQL5/Experts/` และวางไฟล์ EA
   - ไปที่ `MQL5/Include/` และวางไฟล์ library

3. คอมไพล์ EA ใน MetaEditor

4. เปิด EA บนชาร์ตและตั้งค่าพารามิเตอร์:
   - `BUY_THRESHOLD`: 0.6 (ความน่าจะเป็นขั้นต่ำสำหรับ BUY)
   - `SELL_THRESHOLD`: 0.4 (ความน่าจะเป็นสูงสุดสำหรับ SELL)
   - `ENABLE_TRADING`: false (เริ่มต้นให้เป็น false เพื่อทดสอบ)
   - `LOT_SIZE`: 0.1 (ขนาด lot)
   - `MAX_ORDERS`: 3 (จำนวน order สูงสุด)

## Features ที่ใช้ในโมเดล

### โมเดลพื้นฐาน (17 features):
- Price changes
- High/Low ratio
- Open/Close ratio
- Moving averages (5, 10, 20, 50 periods)
- RSI
- Bollinger Bands position
- Volatility ratio
- Momentum indicators
- Support/Resistance distances
- Time-based features

### โมเดลปรับปรุง (14 features):
- Price change
- High/Low ratio
- Body size
- Moving average ratios
- RSI
- Bollinger Bands position
- Momentum indicators
- Volatility
- Time features

## การตั้งค่าที่แนะนำ

### สำหรับการทดสอบ:
- `ENABLE_TRADING`: false
- `BUY_THRESHOLD`: 0.6
- `SELL_THRESHOLD`: 0.4

### สำหรับการเทรดจริง:
- `ENABLE_TRADING`: true
- `BUY_THRESHOLD`: 0.65 (เพิ่มความเข้มงวด)
- `SELL_THRESHOLD`: 0.35 (เพิ่มความเข้มงวด)
- `LOT_SIZE`: 0.01 (เริ่มต้นด้วย lot เล็ก)
- `STOP_LOSS_PIPS`: 20
- `TAKE_PROFIT_PIPS`: 40

## ข้อควรระวัง

1. **ทดสอบก่อนใช้งานจริง**: เริ่มต้นด้วย `ENABLE_TRADING = false` เพื่อดูสัญญาณก่อน
2. **ใช้เงินทุนที่เหมาะสม**: เริ่มต้นด้วย lot เล็ก
3. **ติดตามผล**: ตรวจสอบ win rate และ profit อย่างสม่ำเสมอ
4. **ปรับแต่งพารามิเตอร์**: ปรับ threshold ตามผลการทดสอบ

## ผลการทดสอบ

### โมเดลที่ดีที่สุด: RandomForest
- **Win Rate**: 56.68%
- **ข้อมูล**: 218,420 แถว
- **ช่วงเวลา**: 2024-12-31 ถึง 2025-08-01
- **Features**: 17 technical indicators

### โมเดลปรับปรุง: ExtraTrees
- **Win Rate**: 54.37%
- **AUC**: 56.64%
- **Features**: 14 enhanced features

## การพัฒนาต่อ

1. **เพิ่ม Features**: เพิ่ม technical indicators อื่นๆ
2. **ปรับปรุงโมเดล**: ทดลองกับ deep learning models
3. **Optimization**: ใช้ GridSearchCV เพื่อหา hyperparameters ที่ดีที่สุด
4. **Backtesting**: เพิ่มระบบ backtesting ที่สมบูรณ์
5. **Risk Management**: เพิ่มระบบจัดการความเสี่ยง

## หมายเหตุ

- โมเดลนี้ใช้ข้อมูลย้อนหลังและอาจไม่สามารถทำนายอนาคตได้อย่างแม่นยำ
- ควรใช้ร่วมกับ fundamental analysis และ risk management
- ผลการทดสอบในอดีตไม่รับประกันผลในอนาคต
- ควรทดสอบใน demo account ก่อนใช้งานจริง 