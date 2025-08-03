# Changelog - Binary Option ML Trading System

## Version 2.0 (Latest) - 2024-08-02

### ✅ New Features

#### 1. Offset Bar Support
- **เพิ่มพารามิเตอร์**: `OFFSET_BAR` สำหรับกำหนด offset bar
- **การใช้งาน**:
  - `OFFSET_BAR = 0`: ใช้ current bar (สำหรับ testing)
  - `OFFSET_BAR = 1`: ใช้ T-1 bar (สำหรับ live trading)
  - `OFFSET_BAR = 2`: ใช้ T-2 bar (สำหรับ backtesting)

#### 2. Enhanced Indicator Management
- **เพิ่ม indicator handles**: สำหรับ MA, RSI, Bollinger Bands, StdDev
- **ปรับปรุงประสิทธิภาพ**: ใช้ `CopyBuffer()` แทนการเรียก indicator functions โดยตรง
- **เพิ่ม error handling**: ตรวจสอบ indicator creation และ release handles

#### 3. Improved Library Functions
- **ปรับปรุง**: `calculateFeatures()` รองรับ offset bar
- **เพิ่ม**: `setIndicatorHandles()` สำหรับส่ง handles ไปยัง library
- **ปรับปรุง**: `predictProbability()` และ `getTradingSignal()` รองรับ offset

### 🔧 Technical Improvements

#### 1. BinaryOptionML_EA.mq5
```mql5
// เพิ่มพารามิเตอร์
input int OFFSET_BAR = 1;               // Offset bar for analysis

// เพิ่ม indicator handles
int ma5_handle, ma10_handle, ma20_handle, ma50_handle;
int rsi_handle, bb_handle, std_dev_handle;

// ปรับปรุง OnInit()
- เพิ่มการ init indicators
- เพิ่มการตรวจสอบ error
- เพิ่มการส่ง handles ไปยัง library

// ปรับปรุง OnTick()
- ใช้ offset bar ในการทำนาย
- แสดง offset bar ใน log
```

#### 2. enhanced_extratrees_library.mqh
```mql5
// เพิ่ม external indicator handles
int g_ma5_handle, g_ma10_handle, g_ma20_handle, g_ma50_handle;
int g_rsi_handle, g_bb_handle, g_std_dev_handle;

// เพิ่มฟังก์ชันใหม่
void setIndicatorHandles(int ma5_h, int ma10_h, int ma20_h, int ma50_h, 
                        int rsi_h, int bb_h, int std_dev_h);

// ปรับปรุงฟังก์ชันเดิม
void calculateFeatures(double &features[], int offset_bar = 1);
double predictProbability(int offset_bar = 1);
string getTradingSignal(double buy_threshold = 0.6, double sell_threshold = 0.4, int offset_bar = 1);
```

### 📊 Performance Improvements

1. **Indicator Efficiency**: ใช้ handles แทนการเรียก functions โดยตรง
2. **Memory Management**: เพิ่มการ release handles ใน OnDeinit()
3. **Error Handling**: เพิ่มการตรวจสอบ indicator creation
4. **Backtesting Accuracy**: ใช้ offset bar เพื่อความแม่นยำในการ backtest

### 🎯 Usage Examples

#### สำหรับ Backtesting:
```mql5
BUY_THRESHOLD = 0.6
SELL_THRESHOLD = 0.4
ENABLE_TRADING = true
OFFSET_BAR = 2              // ใช้ T-2 สำหรับการวิเคราะห์
LOT_SIZE = 0.01
```

#### สำหรับ Live Trading:
```mql5
BUY_THRESHOLD = 0.65
SELL_THRESHOLD = 0.35
ENABLE_TRADING = false      // เริ่มต้นด้วย false
OFFSET_BAR = 1              // ใช้ T-1 สำหรับ current bar
LOT_SIZE = 0.01
```

#### สำหรับ Testing:
```mql5
BUY_THRESHOLD = 0.6
SELL_THRESHOLD = 0.4
ENABLE_TRADING = false
OFFSET_BAR = 0              // ใช้ current bar
LOT_SIZE = 0.01
```

### 🚨 Breaking Changes

1. **Library Functions**: ฟังก์ชันใน library ต้องส่ง offset_bar parameter
2. **Indicator Handles**: ต้อง init indicators ใน EA ก่อนใช้งาน
3. **Error Handling**: เพิ่มการตรวจสอบ indicator creation

### 📝 Files Modified

1. **BinaryOptionML_EA.mq5**: เพิ่ม offset bar support และ indicator management
2. **enhanced_extratrees_library.mqh**: ปรับปรุงฟังก์ชันให้รองรับ offset bar
3. **README_UPDATED.md**: เพิ่มคู่มือการใช้งาน offset bar
4. **CHANGELOG.md**: ไฟล์นี้

### 🔮 Future Plans

1. **เพิ่ม Features**: เพิ่ม technical indicators อื่นๆ
2. **Deep Learning**: ทดลองกับ neural networks
3. **Optimization**: ใช้ GridSearchCV เพื่อหา hyperparameters ที่ดีที่สุด
4. **Backtesting**: เพิ่มระบบ backtesting ที่สมบูรณ์
5. **Risk Management**: เพิ่มระบบจัดการความเสี่ยง

---

## Version 1.0 - 2024-08-02

### ✅ Initial Release

- พัฒนาโมเดล ML 4 แบบ (RandomForest, ExtraTrees, GradientBoosting, LogisticRegression)
- สร้าง MQL5 Expert Advisor และ Library
- ได้ Win Rate สูงสุด 56.68% (RandomForest)
- สร้างไฟล์ documentation และ analysis tools 