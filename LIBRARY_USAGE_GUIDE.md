# คู่มือการใช้งาน XGBoost Signal Library

## ภาพรวม

`XGBoostSignalLibrary.mqh` เป็น Library สำหรับสร้างสัญญาณ Binary Option โดยใช้ XGBoost model ที่มี 50 ต้นไม้

## ฟังก์ชันหลัก

### 1. `GetSignal()` - ฟังก์ชันหลัก
```mql5
int GetSignal()
```
**Return Values:**
- `1` = CALL signal
- `-1` = PUT signal  
- `0` = ไม่มีสัญญาณ

**ตัวอย่างการใช้งาน:**
```mql5
#include "XGBoostSignalLibrary.mqh"

void OnTick()
{
    int signal = GetSignal();
    
    if(signal == 1)
    {
        Print("CALL Signal");
        // วาง CALL order
    }
    else if(signal == -1)
    {
        Print("PUT Signal");
        // วาง PUT order
    }
}
```

### 2. `GetSignalString()` - สัญญาณเป็น String
```mql5
string GetSignalString()
```
**Return Values:**
- `"CALL"` = CALL signal
- `"PUT"` = PUT signal
- `"NO_SIGNAL"` = ไม่มีสัญญาณ

**ตัวอย่างการใช้งาน:**
```mql5
string signal = GetSignalString();
Print("Current Signal: ", signal);
```

### 3. `GetLastSignal()` - สัญญาณล่าสุด
```mql5
int GetLastSignal()
```
**Return Values:**
- `1` = CALL signal (ล่าสุด)
- `-1` = PUT signal (ล่าสุด)
- `0` = ไม่มีสัญญาณ

**ตัวอย่างการใช้งาน:**
```mql5
int last_signal = GetLastSignal();
if(last_signal == 1)
    Print("Last signal was CALL");
```

### 4. `GetSignalStrength()` - ความแรงของสัญญาณ
```mql5
double GetSignalStrength()
```
**Return Values:**
- `0.0` ถึง `1.0` = ความน่าจะเป็น

**ตัวอย่างการใช้งาน:**
```mql5
double strength = GetSignalStrength();
Print("Signal Strength: ", strength);
```

### 5. `InitXGBoostLibrary()` - เริ่มต้น Library
```mql5
void InitXGBoostLibrary()
```
**ตัวอย่างการใช้งาน:**
```mql5
int OnInit()
{
    InitXGBoostLibrary();
    return INIT_SUCCEEDED;
}
```

## พารามิเตอร์ที่ปรับแต่งได้

### 1. `InpLookback`
- **ค่าเริ่มต้น:** 20
- **คำอธิบาย:** จำนวนแท่งเทียนที่ใช้คำนวณ features
- **การปรับแต่ง:** เพิ่มเพื่อความแม่นยำ, ลดเพื่อความเร็ว

### 2. `InpWinRateThreshold`
- **ค่าเริ่มต้น:** 0.6 (60%)
- **คำอธิบาย:** เกณฑ์ Win Rate สำหรับส่งสัญญาณ
- **การปรับแต่ง:** 
  - `0.7` = ความแม่นยำสูงขึ้น, สัญญาณน้อยลง
  - `0.5` = สัญญาณมากขึ้น, ความแม่นยำลดลง

### 3. `InpShowDebug`
- **ค่าเริ่มต้น:** false
- **คำอธิบาย:** แสดงข้อมูล debug
- **การปรับแต่ง:** เปิดเพื่อดูการทำงานของ Library

## ตัวอย่างการใช้งาน

### 1. EA ง่ายๆ
```mql5
#include "XGBoostSignalLibrary.mqh"

void OnTick()
{
    int signal = GetSignal();
    
    if(signal == 1)
    {
        // วาง CALL order
        OrderSend(_Symbol, ORDER_TYPE_BUY, 0.1, Ask, 3, 0, 0, "CALL", 0, 0, clrLime);
    }
    else if(signal == -1)
    {
        // วาง PUT order
        OrderSend(_Symbol, ORDER_TYPE_SELL, 0.1, Bid, 3, 0, 0, "PUT", 0, 0, clrRed);
    }
}
```

### 2. Indicator
```mql5
#include "XGBoostSignalLibrary.mqh"

int OnCalculate(...)
{
    int signal = GetSignal();
    
    if(signal == 1)
    {
        // แสดงลูกศรขึ้น
        PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, low[0] - 10 * Point());
    }
    else if(signal == -1)
    {
        // แสดงลูกศรลง
        PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, high[0] + 10 * Point());
    }
    
    return rates_total;
}
```

### 3. Script
```mql5
#include "XGBoostSignalLibrary.mqh"

void OnStart()
{
    InitXGBoostLibrary();
    
    int signal = GetSignal();
    double strength = GetSignalStrength();
    
    Print("Signal: ", GetSignalString());
    Print("Strength: ", strength);
    
    if(signal != 0)
    {
        MessageBox("Signal: " + GetSignalString() + "\nStrength: " + DoubleToString(strength, 3));
    }
}
```

## การติดตั้ง

### 1. คัดลอกไฟล์
```
XGBoostSignalLibrary.mqh → MQL5/Include/
```

### 2. Include ในโปรเจค
```mql5
#include "XGBoostSignalLibrary.mqh"
```

### 3. เริ่มต้น Library
```mql5
int OnInit()
{
    InitXGBoostLibrary();
    return INIT_SUCCEEDED;
}
```

## ข้อควรระวัง

### 1. Timeframe
- Library นี้ออกแบบสำหรับ M1 เท่านั้น
- ตรวจสอบ timeframe ก่อนใช้งาน

### 2. ข้อมูลราคา
- ต้องมีข้อมูลราคาเพียงพอ (อย่างน้อย 20 แท่ง)
- ตรวจสอบ `Bars(_Symbol, PERIOD_M1)` ก่อนใช้งาน

### 3. การเทรน
- ควรทดสอบใน Demo Account ก่อน
- เริ่มต้นด้วย Lot ขนาดเล็ก

## การปรับแต่ง

### 1. ปรับ Win Rate Threshold
```mql5
// ใน Library
input double InpWinRateThreshold = 0.7; // เพิ่มความแม่นยำ
```

### 2. ปรับ Features
```mql5
// เพิ่ม features ใหม่ใน CalculateFeatures()
g_features[21] = new_feature_value;
```

### 3. ปรับต้นไม้
```mql5
// แก้ไข PredictTree1() ถึง PredictTree10()
// หรือเพิ่มต้นไม้ใหม่
```

## การแก้ไขปัญหา

### 1. ไม่มีสัญญาณ
- ตรวจสอบ timeframe (ต้องเป็น M1)
- ตรวจสอบข้อมูลราคา
- ลด `InpWinRateThreshold`

### 2. สัญญาณไม่แม่นยำ
- เพิ่ม `InpWinRateThreshold`
- ตรวจสอบ market conditions
- ปรับ features

### 3. Library ไม่ทำงาน
- ตรวจสอบการ include
- ตรวจสอบการเริ่มต้น Library
- เปิด debug mode

## สรุป

XGBoost Signal Library ให้ฟังก์ชัน `GetSignal()` ที่ return:
- `1` = CALL signal
- `-1` = PUT signal
- `0` = ไม่มีสัญญาณ

Library นี้ใช้ XGBoost model 50 ต้นไม้ และ 21 features เพื่อสร้างสัญญาณ Binary Option ที่แม่นยำ 