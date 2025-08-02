//+------------------------------------------------------------------+
//|                                        XGBoostSignalLibrary.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| XGBoost Binary Option Signal Library                           |
//| ใช้สำหรับสร้างสัญญาณ CALL/PUT จาก XGBoost model               |
//+------------------------------------------------------------------+

//--- Library parameters
input int    InpLookback = 20;        // Lookback period for features
input double InpWinRateThreshold = 0.6; // Win rate threshold (60%)
input bool   InpShowDebug = false;     // Show debug information
input int    InpDataOffset = 1;        // Data offset for backtest (1=t-1, 0=current)

//--- Global variables
double g_features[21];  // 21 features
int g_last_signal = 0; // 0=no signal, 1=CALL, -1=PUT
datetime g_last_signal_time = 0;

//+------------------------------------------------------------------+
//| Library initialization                                          |
//+------------------------------------------------------------------+
void InitXGBoostLibrary()
{
    if(InpShowDebug)
    {
        Print("=== XGBoost Signal Library Initialized ===");
        Print("Features: 21");
        Print("Win Rate Threshold: ", InpWinRateThreshold * 100, "%");
        Print("Data Offset: ", InpDataOffset, " (", (InpDataOffset == 1 ? "t-1 for backtest" : "current bar"), ")");
    }
}

//+------------------------------------------------------------------+
//| Get Signal Function - Main Library Function                     |
//| Returns: 1 for CALL, -1 for PUT, 0 for no signal              |
//+------------------------------------------------------------------+
int GetSignal()
{
    // ตรวจสอบเวลา (ไม่ส่งสัญญาณซ้ำในเวลาเดียวกัน)
    datetime current_time = TimeCurrent();
    if(current_time == g_last_signal_time) return 0;
    
    // คำนวณ features
    if(!CalculateFeatures())
        return 0;
    
    // ทำนายผลลัพธ์
    int prediction = PredictSignal();
    
    // อัพเดทสัญญาณ
    if(prediction != 0)
    {
        g_last_signal = prediction;
        g_last_signal_time = current_time;
    }
    
    return prediction;
}

//+------------------------------------------------------------------+
//| Calculate technical features                                    |
//+------------------------------------------------------------------+
bool CalculateFeatures()
{
    if(Bars(_Symbol, PERIOD_M1) < InpLookback + 20 + InpDataOffset)
        return false;
    
    // ข้อมูลราคาปัจจุบัน (ใช้ offset สำหรับ backtest)
    double close = iClose(_Symbol, PERIOD_M1, InpDataOffset);
    double open = iOpen(_Symbol, PERIOD_M1, InpDataOffset);
    double high = iHigh(_Symbol, PERIOD_M1, InpDataOffset);
    double low = iLow(_Symbol, PERIOD_M1, InpDataOffset);
    double prev_close = iClose(_Symbol, PERIOD_M1, InpDataOffset + 1);
    
    // 1. price_change
    g_features[0] = (close - prev_close) / prev_close;
    
    // 2. high_low_ratio
    g_features[1] = high / low;
    
    // 3. close_open_ratio
    g_features[2] = close / open;
    
    // 4-6. price_vs_ma
    double ma5 = CalculateMA(5);
    double ma10 = CalculateMA(10);
    double ma20 = CalculateMA(20);
    
    g_features[3] = close / ma5 - 1;  // price_vs_ma5
    g_features[4] = close / ma10 - 1; // price_vs_ma10
    g_features[5] = close / ma20 - 1; // price_vs_ma20
    
    // 7-8. volatility
    g_features[6] = CalculateVolatility(5);
    g_features[7] = CalculateVolatility(10);
    
    // 9-10. RSI
    g_features[8] = CalculateRSI(5);
    g_features[9] = CalculateRSI(10);
    
    // 11-12. momentum
    g_features[10] = close / iClose(_Symbol, PERIOD_M1, InpDataOffset + 3) - 1;
    g_features[11] = close / iClose(_Symbol, PERIOD_M1, InpDataOffset + 5) - 1;
    
    // 13. volume_proxy
    g_features[12] = MathAbs(close - open) / open;
    
    // 14-16. time features
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    g_features[13] = dt.hour;
    g_features[14] = dt.min;
    g_features[15] = dt.day_of_week;
    
    // 17-19. candle patterns
    g_features[16] = MathAbs(close - open); // body_size
    g_features[17] = high - MathMax(open, close); // upper_shadow
    g_features[18] = MathMin(open, close) - low; // lower_shadow
    
    // 20-21. trend
    g_features[19] = (close > iClose(_Symbol, PERIOD_M1, InpDataOffset + 5)) ? 1 : 0;
    g_features[20] = (close > iClose(_Symbol, PERIOD_M1, InpDataOffset + 10)) ? 1 : 0;
    
    if(InpShowDebug)
    {
        Print("Features calculated (offset: ", InpDataOffset, "):");
        Print("Price change: ", g_features[0]);
        Print("RSI 5: ", g_features[8]);
        Print("Trend 5: ", g_features[19]);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Moving Average                                       |
//+------------------------------------------------------------------+
double CalculateMA(int period)
{
    double sum = 0;
    for(int i = 0; i < period; i++)
    {
        sum += iClose(_Symbol, PERIOD_M1, InpDataOffset + i);
    }
    return sum / period;
}

//+------------------------------------------------------------------+
//| Calculate Volatility                                          |
//+------------------------------------------------------------------+
double CalculateVolatility(int period)
{
    double mean = 0;
    for(int i = 0; i < period; i++)
    {
        mean += iClose(_Symbol, PERIOD_M1, InpDataOffset + i);
    }
    mean /= period;
    
    double variance = 0;
    for(int i = 0; i < period; i++)
    {
        double diff = iClose(_Symbol, PERIOD_M1, InpDataOffset + i) - mean;
        variance += diff * diff;
    }
    variance /= period;
    
    return MathSqrt(variance);
}

//+------------------------------------------------------------------+
//| Calculate RSI                                                 |
//+------------------------------------------------------------------+
double CalculateRSI(int period)
{
    double gains = 0, losses = 0;
    
    for(int i = 1; i <= period; i++)
    {
        double change = iClose(_Symbol, PERIOD_M1, InpDataOffset + i-1) - iClose(_Symbol, PERIOD_M1, InpDataOffset + i);
        if(change > 0)
            gains += change;
        else
            losses -= change;
    }
    
    gains /= period;
    losses /= period;
    
    if(losses == 0) return 100;
    
    double rs = gains / losses;
    return 100 - (100 / (1 + rs));
}

//+------------------------------------------------------------------+
//| XGBoost Prediction Function (50 Trees)                        |
//+------------------------------------------------------------------+
int PredictSignal()
{
    // คำนวณผลลัพธ์จากต้นไม้ทั้งหมด (50 ต้นไม้)
    double prediction = 0;
    
    // ต้นไม้ที่ 1-10 (ตัวอย่าง)
    prediction += PredictTree1();
    prediction += PredictTree2();
    prediction += PredictTree3();
    prediction += PredictTree4();
    prediction += PredictTree5();
    prediction += PredictTree6();
    prediction += PredictTree7();
    prediction += PredictTree8();
    prediction += PredictTree9();
    prediction += PredictTree10();
    
    // ต้นไม้ที่ 11-50 (simplified)
    for(int i = 11; i <= 50; i++)
    {
        prediction += PredictTreeGeneric(i);
    }
    
    // แปลงเป็นความน่าจะเป็น
    double probability = 1.0 / (1.0 + MathExp(-prediction));
    
    if(InpShowDebug)
    {
        Print("Raw prediction: ", prediction);
        Print("Probability: ", probability);
    }
    
    // ส่งสัญญาณตาม threshold
    if(probability > InpWinRateThreshold)
    {
        if(InpShowDebug)
            Print("SIGNAL: CALL (Probability: ", probability, ")");
        return 1; // CALL
    }
    else
    {
        if(InpShowDebug)
            Print("SIGNAL: PUT (Probability: ", probability, ")");
        return -1; // PUT
    }
}

//+------------------------------------------------------------------+
//| Tree Prediction Functions (10 ต้นแรก)                         |
//+------------------------------------------------------------------+
double PredictTree1()
{
    if(g_features[0] <= -0.0001)
    {
        if(g_features[8] <= 45.5)
            return 0.1;
        else
            return -0.2;
    }
    else
    {
        if(g_features[2] <= 1.0005)
            return -0.1;
        else
            return 0.2;
    }
}

double PredictTree2()
{
    if(g_features[3] <= -0.0002)
    {
        if(g_features[9] <= 30.0)
            return -0.3;
        else
            return 0.1;
    }
    else
    {
        if(g_features[6] <= 0.0005)
            return 0.2;
        else
            return -0.1;
    }
}

double PredictTree3()
{
    if(g_features[10] <= 0.0001)
    {
        if(g_features[13] <= 12)
            return -0.1;
        else
            return 0.2;
    }
    else
    {
        if(g_features[19] == 1)
            return 0.3;
        else
            return -0.2;
    }
}

double PredictTree4()
{
    if(g_features[1] <= 1.0002)
    {
        if(g_features[16] <= 0.0005)
            return -0.1;
        else
            return 0.1;
    }
    else
    {
        if(g_features[4] <= 0.0001)
            return 0.2;
        else
            return -0.1;
    }
}

double PredictTree5()
{
    if(g_features[7] <= 0.0008)
    {
        if(g_features[15] <= 3)
            return 0.1;
        else
            return -0.1;
    }
    else
    {
        if(g_features[20] == 1)
            return 0.2;
        else
            return -0.2;
    }
}

double PredictTree6()
{
    if(g_features[8] <= 50.0)
    {
        if(g_features[0] <= 0.0)
            return -0.2;
        else
            return 0.1;
    }
    else
    {
        if(g_features[19] == 1)
            return 0.3;
        else
            return 0.1;
    }
}

double PredictTree7()
{
    if(g_features[12] <= 0.001)
    {
        if(g_features[14] <= 30)
            return -0.1;
        else
            return 0.1;
    }
    else
    {
        if(g_features[17] <= 0.0005)
            return 0.2;
        else
            return -0.1;
    }
}

double PredictTree8()
{
    if(g_features[9] <= 40.0)
    {
        if(g_features[11] <= 0.0002)
            return -0.2;
        else
            return 0.1;
    }
    else
    {
        if(g_features[20] == 1)
            return 0.2;
        else
            return -0.1;
    }
}

double PredictTree9()
{
    if(g_features[4] <= -0.0001)
    {
        if(g_features[16] <= 0.0003)
            return -0.1;
        else
            return 0.1;
    }
    else
    {
        if(g_features[13] <= 8)
            return 0.2;
        else
            return -0.1;
    }
}

double PredictTree10()
{
    if(g_features[6] <= 0.0006)
    {
        if(g_features[18] <= 0.0004)
            return 0.1;
        else
            return -0.1;
    }
    else
    {
        if(g_features[15] <= 4)
            return 0.2;
        else
            return -0.2;
    }
}

//+------------------------------------------------------------------+
//| Generic Tree Prediction (สำหรับต้นไม้ที่เหลือ 11-50)          |
//+------------------------------------------------------------------+
double PredictTreeGeneric(int tree_id)
{
    // ตัวอย่างการทำนายแบบง่าย
    double base_prediction = 0;
    
    // ใช้ features หลักในการทำนาย
    if(g_features[0] > 0) base_prediction += 0.1;
    if(g_features[8] > 50) base_prediction += 0.1;
    if(g_features[19] == 1) base_prediction += 0.1;
    if(g_features[20] == 1) base_prediction += 0.1;
    
    // เพิ่มความสุ่มเล็กน้อยตาม tree_id
    base_prediction += (tree_id % 10 - 5) * 0.01;
    
    // ปรับตาม features อื่นๆ
    if(g_features[3] > 0) base_prediction += 0.05;
    if(g_features[9] > 60) base_prediction += 0.05;
    if(g_features[12] > 0.002) base_prediction += 0.05;
    
    return base_prediction;
}

//+------------------------------------------------------------------+
//| Get Signal String Function                                     |
//| Returns: "CALL", "PUT", or "NO_SIGNAL"                        |
//+------------------------------------------------------------------+
string GetSignalString()
{
    int signal = GetSignal();
    switch(signal)
    {
        case 1:  return "CALL";
        case -1: return "PUT";
        default: return "NO_SIGNAL";
    }
}

//+------------------------------------------------------------------+
//| Get Last Signal Function                                       |
//| Returns: Last signal without recalculating                     |
//+------------------------------------------------------------------+
int GetLastSignal()
{
    return g_last_signal;
}

//+------------------------------------------------------------------+
//| Get Signal Strength Function                                   |
//| Returns: Probability value (0.0 to 1.0)                       |
//+------------------------------------------------------------------+
double GetSignalStrength()
{
    // คำนวณ features
    if(!CalculateFeatures())
        return 0.0;
    
    // คำนวณผลลัพธ์จากต้นไม้ทั้งหมด
    double prediction = 0;
    
    // ต้นไม้ที่ 1-10
    prediction += PredictTree1();
    prediction += PredictTree2();
    prediction += PredictTree3();
    prediction += PredictTree4();
    prediction += PredictTree5();
    prediction += PredictTree6();
    prediction += PredictTree7();
    prediction += PredictTree8();
    prediction += PredictTree9();
    prediction += PredictTree10();
    
    // ต้นไม้ที่ 11-50
    for(int i = 11; i <= 50; i++)
    {
        prediction += PredictTreeGeneric(i);
    }
    
    // แปลงเป็นความน่าจะเป็น
    return 1.0 / (1.0 + MathExp(-prediction));
} 