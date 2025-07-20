# Binary Option M1 Signal Library - Quick Reference

## 📦 ไฟล์ที่ต้องมี

```
📁 MQL5/Include/
├── BinaryOptionM1_SignalLibrary.mqh    // Signal library
└── Example_EA_Using_BinarySignal.mq5   // ตัวอย่างการใช้งาน
```

## 🚀 การใช้งานเบื้องต้น

### 1. **Include Library**
```mql5
#include "BinaryOptionM1_SignalLibrary.mqh"
```

### 2. **Initialize System**
```mql5
int OnInit() {
    // Initialize with default parameters (easy way)
    if(!InitializeBinarySignalSystem()) {
        Print("Failed to initialize signal system");
        return INIT_FAILED;
    }
    return INIT_SUCCEEDED;
}
```

### 3. **Get Signal**
```mql5
void OnTick() {
    BinarySignal signal = GetBinarySignal();
    
    if(signal.isValid && signal.confidence >= 70.0) {
        Print("Signal: ", SignalDirectionToString(signal.direction));
        Print("Confidence: ", signal.confidence, "%");
        
        // Your trading logic here
        if(signal.direction == SIGNAL_CALL) {
            // Execute CALL trade
        }
        else if(signal.direction == SIGNAL_PUT) {
            // Execute PUT trade
        }
    }
}
```

### 4. **Cleanup**
```mql5
void OnDeinit(const int reason) {
    CleanupBinarySignalSystem();
}
```

## 📊 Signal Structure

```mql5
struct BinarySignal {
    SIGNAL_DIRECTION direction;     // SIGNAL_CALL, SIGNAL_PUT, SIGNAL_NONE
    SIGNAL_STRENGTH strength;       // STRENGTH_WEAK, STRENGTH_MODERATE, STRENGTH_STRONG
    double confidence;              // 0-100%
    double totalScore;              // Combined indicator score
    double trendScore;              // EMA component score
    double momentumScore;           // RSI + MACD score
    double oscillatorScore;         // Stochastic + BB score
    double volumeScore;             // Volume confirmation score
    string reason;                  // Signal explanation
    datetime timestamp;             // Signal time
    double entryPrice;              // Suggested entry price
    bool isValid;                   // Signal validity
    bool m5Confirmed;               // M5 timeframe confirmation
    bool volumeConfirmed;           // Volume confirmation
    bool adxConfirmed;              // ADX strength confirmation
};
```

## ⚙️ การใช้งานขั้นสูง

### **Custom Parameters**
```mql5
SignalParameters customParams;
customParams.emaFast = 21;
customParams.emaSlow = 55;
customParams.minConfidence = 75.0;
customParams.useMultiTimeframe = true;
// ... set other parameters

InitializeBinarySignalSystem(Symbol(), true, customParams);
```

### **Parameter Customization**
```mql5
struct SignalParameters {
    // Indicator Settings
    int emaFast;                    // Default: 21
    int emaSlow;                    // Default: 55
    int rsiPeriod;                  // Default: 14
    int macdFast;                   // Default: 12
    int macdSlow;                   // Default: 26
    int macdSignal;                 // Default: 9
    int stochK;                     // Default: 14
    int stochD;                     // Default: 3
    int bbPeriod;                   // Default: 20
    double bbDeviation;             // Default: 2.0
    int adxPeriod;                  // Default: 14
    int volumeMAPeriod;             // Default: 20
    
    // Signal Thresholds
    double minConfidence;           // Default: 70.0
    double strongSignalThreshold;   // Default: 70.0
    double moderateSignalThreshold; // Default: 60.0
    double weakSignalThreshold;     // Default: 50.0
    
    // Filters
    bool useMultiTimeframe;         // Default: true
    bool useVolumeFilter;           // Default: true
    bool useADXFilter;              // Default: true
    double minADXLevel;             // Default: 25.0
};
```

## 🎯 Main Functions

### **GetBinarySignal()**
```mql5
BinarySignal GetBinarySignal(string symbol = "");
// Returns complete signal information
```

### **GetQuickSignal()**
```mql5
int GetQuickSignal(string symbol = "", double minConfidence = 70.0);
// Returns: 1 = CALL, -1 = PUT, 0 = No Signal
```

### **Utility Functions**
```mql5
string SignalDirectionToString(SIGNAL_DIRECTION direction);
string SignalStrengthToString(SIGNAL_STRENGTH strength);
void PrintSignalInfo(BinarySignal &signal);
bool IsSignalSystemReady();
```

## 💡 ตัวอย่างการใช้งานจริง

### **1. Simple Signal Check**
```mql5
void CheckSignals() {
    int signal = GetQuickSignal("EURUSD", 75.0);
    
    if(signal == 1) {
        Print("CALL signal detected for EURUSD");
        // Execute CALL trade
    }
    else if(signal == -1) {
        Print("PUT signal detected for EURUSD");
        // Execute PUT trade
    }
}
```

### **2. Detailed Signal Analysis**
```mql5
void AnalyzeSignal() {
    BinarySignal signal = GetBinarySignal("EURUSD");
    
    Print("=== Signal Analysis ===");
    Print("Direction: ", SignalDirectionToString(signal.direction));
    Print("Strength: ", SignalStrengthToString(signal.strength));
    Print("Confidence: ", signal.confidence, "%");
    Print("Components:");
    Print("  Trend: ", signal.trendScore);
    Print("  Momentum: ", signal.momentumScore);
    Print("  Oscillator: ", signal.oscillatorScore);
    Print("  Volume: ", signal.volumeScore);
    Print("Confirmations:");
    Print("  M5 Trend: ", signal.m5Confirmed);
    Print("  ADX Strong: ", signal.adxConfirmed);
    Print("  Volume: ", signal.volumeConfirmed);
    Print("Valid: ", signal.isValid);
    Print("Reason: ", signal.reason);
}
```

### **3. Multi-Symbol Monitoring**
```mql5
void MonitorMultipleSymbols() {
    string symbols[] = {"EURUSD", "GBPUSD", "USDJPY", "AUDUSD"};
    
    for(int i = 0; i < ArraySize(symbols); i++) {
        BinarySignal signal = GetBinarySignal(symbols[i]);
        
        if(signal.isValid && signal.confidence >= 70.0) {
            Print(symbols[i], ": ", SignalDirectionToString(signal.direction), 
                  " (", signal.confidence, "%)");
        }
    }
}
```

### **4. Signal Filtering**
```mql5
bool IsHighQualitySignal(BinarySignal &signal) {
    // Custom filtering criteria
    if(!signal.isValid) return false;
    if(signal.confidence < 75.0) return false;
    if(signal.strength < STRENGTH_MODERATE) return false;
    if(!signal.m5Confirmed) return false;
    if(!signal.adxConfirmed) return false;
    
    return true;
}

void ProcessHighQualitySignals() {
    BinarySignal signal = GetBinarySignal();
    
    if(IsHighQualitySignal(signal)) {
        Print("🌟 HIGH QUALITY SIGNAL: ", signal.reason);
        // Execute trade with higher confidence
    }
}
```

## 🔧 Integration Examples

### **With MT2Trading**
```mql5
void SendToMT2Trading(BinarySignal &signal, double amount) {
    if(signal.isValid && signal.confidence >= 75.0) {
        string direction = SignalDirectionToString(signal.direction);
        string signalID = "BM1_" + TimeToString(TimeCurrent());
        
        // mt2trading(Symbol(), direction, amount, 1, 0, 1, 1.0, 
        //           broker, "BinaryM1", signalID);
    }
}
```

### **With Risk Management**
```mql5
double CalculatePosition(BinarySignal &signal) {
    double baseAmount = 10.0;
    double multiplier = 1.0;
    
    // Adjust based on signal strength
    switch(signal.strength) {
        case STRENGTH_STRONG:   multiplier = 1.5; break;
        case STRENGTH_MODERATE: multiplier = 1.0; break;
        case STRENGTH_WEAK:     multiplier = 0.5; break;
    }
    
    // Adjust based on confidence
    if(signal.confidence >= 85.0) multiplier *= 1.2;
    else if(signal.confidence < 70.0) multiplier *= 0.8;
    
    return baseAmount * multiplier;
}
```

### **With Time Filters**
```mql5
bool IsGoodTradingTime() {
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    
    // London session
    if(dt.hour >= 8 && dt.hour < 17) return true;
    
    // New York session
    if(dt.hour >= 13 && dt.hour < 22) return true;
    
    return false;
}

void ProcessSignalWithTimeFilter() {
    if(!IsGoodTradingTime()) return;
    
    BinarySignal signal = GetBinarySignal();
    
    if(signal.isValid) {
        // Process signal during good trading hours
    }
}
```

## 📈 Performance Tips

### **1. Optimize Signal Frequency**
```mql5
// Check signals only on new bars
static datetime lastCheck = 0;
datetime currentTime = iTime(Symbol(), PERIOD_M1, 0);

if(currentTime != lastCheck) {
    lastCheck = currentTime;
    BinarySignal signal = GetBinarySignal();
    // Process signal
}
```

### **2. Cache Signal Results**
```mql5
// Cache the last signal to avoid recalculation
static BinarySignal lastSignal;
static datetime lastSignalTime = 0;

datetime currentTime = TimeCurrent();
if(currentTime - lastSignalTime > 60) { // Update every minute
    lastSignal = GetBinarySignal();
    lastSignalTime = currentTime;
}

// Use lastSignal for decisions
```

### **3. Validate Before Use**
```mql5
bool ValidateSignalForTrading(BinarySignal &signal) {
    if(!IsSignalSystemReady()) return false;
    if(!signal.isValid) return false;
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < 70.0) return false;
    
    return true;
}
```

## ⚠️ Important Notes

1. **Always initialize** the system before use
2. **Check IsSignalSystemReady()** before getting signals
3. **Validate signals** according to your criteria
4. **Use appropriate timeframes** (M1 for binary options)
5. **Consider multiple confirmations** for higher accuracy
6. **Test thoroughly** before live trading
7. **Monitor performance** and adjust parameters as needed

## 🎯 Quick Integration Checklist

- [ ] Include library in your EA
- [ ] Initialize system in OnInit()
- [ ] Check signals on new bars
- [ ] Validate signal quality
- [ ] Apply your risk management
- [ ] Execute trades
- [ ] Monitor results
- [ ] Cleanup in OnDeinit()

นี่คือ library ที่พร้อมใช้งานและสามารถนำไปรวมกับ EA ใดๆ ได้ทันทีครับ! 🚀 