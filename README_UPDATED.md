# Binary Option ML Trading System (Updated)

ระบบ Machine Learning สำหรับเทรด Binary Option ที่พัฒนาด้วย Python และ MQL5

## การปรับปรุงล่าสุด

### ✅ เพิ่ม Offset Bar Support
- สามารถกำหนด offset bar สำหรับการวิเคราะห์ได้
- เหมาะสำหรับ backtesting ที่ใช้ T-2 สำหรับวิเคราะห์ และ T-1 สำหรับ current bar
- รองรับ indicator handles เพื่อประสิทธิภาพที่ดีขึ้น

### ✅ ปรับปรุง Indicator Initialization
- เพิ่มการ init indicators ใน OnInit()
- ใช้ indicator handles แทนการเรียก indicator functions โดยตรง
- เพิ่มการตรวจสอบ error และ release handles

## การตั้งค่า Offset Bar

### สำหรับ Backtesting:
```mql5
input int OFFSET_BAR = 2;  // ใช้ T-2 สำหรับการวิเคราะห์
```

### สำหรับ Live Trading:
```mql5
input int OFFSET_BAR = 1;  // ใช้ T-1 สำหรับ current bar
```

### สำหรับ Testing:
```mql5
input int OFFSET_BAR = 0;  // ใช้ current bar
```

## วิธีการใช้งาน

### 1. ติดตั้ง Dependencies
```bash
pip install -r requirements.txt
```

### 2. รันการเทรนโมเดล
```bash
python ml_models.py          # โมเดลพื้นฐาน
python enhanced_ml_models.py # โมเดลปรับปรุง
```

### 3. ใช้งานใน MetaTrader 5

1. **คัดลอกไฟล์ไปยัง MT5**:
   - `BinaryOptionML_EA.mq5` → `MQL5/Experts/`
   - `enhanced_extratrees_library.mqh` → `MQL5/Include/`

2. **คอมไพล์ EA ใน MetaEditor**

3. **ตั้งค่าพารามิเตอร์**:
   ```mql5
   BUY_THRESHOLD: 0.6
   SELL_THRESHOLD: 0.4
   ENABLE_TRADING: false    // เริ่มต้นด้วย false
   LOT_SIZE: 0.01
   OFFSET_BAR: 1            // ใช้ T-1 สำหรับ current bar
   MAX_ORDERS: 3
   ```

## ผลการทดสอบโมเดล

### โมเดลที่ดีที่สุด: RandomForest
- **Win Rate**: 56.68%
- **Accuracy**: 56.68%
- **Features**: 17 technical indicators

### โมเดลปรับปรุง: ExtraTrees
- **Win Rate**: 54.37%
- **AUC**: 56.64%
- **Features**: 14 enhanced features

## การตั้งค่าสำหรับ Backtesting

### Strategy Tester Settings:
1. **Model**: Every tick based on real ticks
2. **Spread**: ตามที่ต้องการ
3. **Optimization**: Disabled (สำหรับการทดสอบ)

### EA Parameters:
```mql5
BUY_THRESHOLD = 0.6
SELL_THRESHOLD = 0.4
ENABLE_TRADING = true       // เปิดการเทรดสำหรับ backtest
OFFSET_BAR = 2              // ใช้ T-2 สำหรับการวิเคราะห์
LOT_SIZE = 0.01
MAX_ORDERS = 3
STOP_LOSS_PIPS = 20
TAKE_PROFIT_PIPS = 40
```

## การตั้งค่าสำหรับ Live Trading

### EA Parameters:
```mql5
BUY_THRESHOLD = 0.65       // เพิ่มความเข้มงวด
SELL_THRESHOLD = 0.35      // เพิ่มความเข้มงวด
ENABLE_TRADING = false      // เริ่มต้นด้วย false
OFFSET_BAR = 1              // ใช้ T-1 สำหรับ current bar
LOT_SIZE = 0.01
MAX_ORDERS = 3
```

## ข้อควรระวัง

1. **ทดสอบก่อนใช้งานจริง**: เริ่มต้นด้วย `ENABLE_TRADING = false`
2. **ใช้เงินทุนที่เหมาะสม**: เริ่มต้นด้วย lot เล็ก
3. **ติดตามผล**: ตรวจสอบ win rate และ profit อย่างสม่ำเสมอ
4. **ปรับแต่งพารามิเตอร์**: ปรับ threshold ตามผลการทดสอบ
5. **Offset Bar**: ใช้ค่าที่เหมาะสมตามการใช้งาน

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
- Offset bar ช่วยให้การ backtesting มีความแม่นยำมากขึ้น 