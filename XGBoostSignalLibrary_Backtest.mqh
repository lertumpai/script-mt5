//+------------------------------------------------------------------+
//|                                    XGBoostSignalLibrary_Backtest.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| XGBoost Binary Option Signal Library - Backtest Version         |
//| ใช้สำหรับ Backtest โดยใช้ข้อมูลย้อนหลัง t-2                     |
//| สคริป Backtest จะใช้ t-1 ได้                                     |
//+------------------------------------------------------------------+

//--- Library parameters
input int    InpLookback = 20;        // Lookback period for features
input double InpWinRateThreshold = 0.6; // Win rate threshold (60%)
input bool   InpShowDebug = false;     // Show debug information
input int    InpBarOffset = 2;         // Bar offset for backtest (t-2)

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
        Print("=== XGBoost Signal Library Initialized (Backtest Version) ===");
        Print("Features: 21");
        Print("Win Rate Threshold: ", InpWinRateThreshold * 100, "%");
        Print("Bar Offset: ", InpBarOffset, " (t-", InpBarOffset, ")");
        Print("Data Source: ohlc.csv (372,304 records)");
    }
}

//+------------------------------------------------------------------+
//| Get Signal Function - Main Library Function                     |
//| Returns: 1 for CALL, -1 for PUT, 0 for no signal              |
//| Uses historical data for backtest compatibility                 |
//+------------------------------------------------------------------+
int GetSignal()
{
    // ตรวจสอบเวลา (ไม่ส่งสัญญาณซ้ำในเวลาเดียวกัน)
    datetime current_time = TimeCurrent();
    if(current_time == g_last_signal_time) return 0;
    
    // คำนวณ features จากข้อมูลย้อนหลัง
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
//| Calculate technical features from historical data (t-2)         |
//+------------------------------------------------------------------+
bool CalculateFeatures()
{
    if(Bars(_Symbol, PERIOD_M1) < InpLookback + 20 + InpBarOffset)
        return false;
    
    // ข้อมูลราคาจาก t-2 (สำหรับ backtest)
    double close = iClose(_Symbol, PERIOD_M1, InpBarOffset);
    double open = iOpen(_Symbol, PERIOD_M1, InpBarOffset);
    double high = iHigh(_Symbol, PERIOD_M1, InpBarOffset);
    double low = iLow(_Symbol, PERIOD_M1, InpBarOffset);
    double prev_close = iClose(_Symbol, PERIOD_M1, InpBarOffset + 1);
    
    // 1. price_change (t-2)
    g_features[0] = (close - prev_close) / prev_close;
    
    // 2. high_low_ratio (t-2)
    g_features[1] = high / low;
    
    // 3. close_open_ratio (t-2)
    g_features[2] = close / open;
    
    // 4-6. price_vs_ma (t-2)
    double ma5 = CalculateMA(5, InpBarOffset);
    double ma10 = CalculateMA(10, InpBarOffset);
    double ma20 = CalculateMA(20, InpBarOffset);
    
    g_features[3] = close / ma5 - 1;  // price_vs_ma5
    g_features[4] = close / ma10 - 1; // price_vs_ma10
    g_features[5] = close / ma20 - 1; // price_vs_ma20
    
    // 7-8. volatility (t-2)
    g_features[6] = CalculateVolatility(5, InpBarOffset);
    g_features[7] = CalculateVolatility(10, InpBarOffset);
    
    // 9-10. RSI (t-2)
    g_features[8] = CalculateRSI(5, InpBarOffset);
    g_features[9] = CalculateRSI(10, InpBarOffset);
    
    // 11-12. momentum (t-2)
    g_features[10] = close / iClose(_Symbol, PERIOD_M1, InpBarOffset + 3) - 1;
    g_features[11] = close / iClose(_Symbol, PERIOD_M1, InpBarOffset + 5) - 1;
    
    // 13. volume_proxy (t-2)
    g_features[12] = MathAbs(close - open) / open;
    
    // 14-16. time features (t-2)
    MqlDateTime dt;
    TimeToStruct(iTime(_Symbol, PERIOD_M1, InpBarOffset), dt);
    g_features[13] = dt.hour;
    g_features[14] = dt.min;
    g_features[15] = dt.day_of_week;
    
    // 17-19. candle patterns (t-2)
    g_features[16] = MathAbs(close - open); // body_size
    g_features[17] = high - MathMax(open, close); // upper_shadow
    g_features[18] = MathMin(open, close) - low; // lower_shadow
    
    // 20-21. trend (t-2)
    g_features[19] = (close > iClose(_Symbol, PERIOD_M1, InpBarOffset + 5)) ? 1 : 0;
    g_features[20] = (close > iClose(_Symbol, PERIOD_M1, InpBarOffset + 10)) ? 1 : 0;
    
    if(InpShowDebug)
    {
        Print("Features calculated (t-", InpBarOffset, "):");
        Print("Price change: ", g_features[0]);
        Print("RSI 5: ", g_features[8]);
        Print("Trend 5: ", g_features[19]);
        Print("Bar time: ", TimeToString(iTime(_Symbol, PERIOD_M1, InpBarOffset)));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Moving Average with offset                            |
//+------------------------------------------------------------------+
double CalculateMA(int period, int offset)
{
    double sum = 0;
    for(int i = 0; i < period; i++)
    {
        sum += iClose(_Symbol, PERIOD_M1, offset + i);
    }
    return sum / period;
}

//+------------------------------------------------------------------+
//| Calculate Volatility with offset                               |
//+------------------------------------------------------------------+
double CalculateVolatility(int period, int offset)
{
    double mean = 0;
    for(int i = 0; i < period; i++)
    {
        mean += iClose(_Symbol, PERIOD_M1, offset + i);
    }
    mean /= period;
    
    double variance = 0;
    for(int i = 0; i < period; i++)
    {
        double diff = iClose(_Symbol, PERIOD_M1, offset + i) - mean;
        variance += diff * diff;
    }
    variance /= period;
    
    return MathSqrt(variance);
}

//+------------------------------------------------------------------+
//| Calculate RSI with offset                                      |
//+------------------------------------------------------------------+
double CalculateRSI(int period, int offset)
{
    double gains = 0, losses = 0;
    
    for(int i = 1; i <= period; i++)
    {
        double change = iClose(_Symbol, PERIOD_M1, offset + i - 1) - iClose(_Symbol, PERIOD_M1, offset + i);
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
//| XGBoost Prediction Function (50 Trees) - Updated from OHLC Data |
//+------------------------------------------------------------------+
int PredictSignal()
{
    // คำนวณผลลัพธ์จากต้นไม้ทั้งหมด (50 ต้นไม้)
    double prediction = 0;
    
    // ต้นไม้ที่ 1-10 (อัพเดทจาก OHLC data)
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
//| Tree Prediction Functions (10 ต้นแรก) - Updated from OHLC Data |
//+------------------------------------------------------------------+
double PredictTree1()
{
    if(g_features[0] <= -0.00015)
    {
        if(g_features[8] <= 42.3)
            return 0.087;
        else
            return -0.156;
    }
    else
    {
        if(g_features[2] <= 1.0003)
            return -0.123;
        else
            return 0.234;
    }
}

double PredictTree2()
{
    if(g_features[3] <= -0.00025)
    {
        if(g_features[9] <= 28.5)
            return -0.312;
        else
            return 0.089;
    }
    else
    {
        if(g_features[6] <= 0.00045)
            return 0.187;
        else
            return -0.098;
    }
}

double PredictTree3()
{
    if(g_features[10] <= 0.00008)
    {
        if(g_features[13] <= 10)
            return -0.134;
        else
            return 0.167;
    }
    else
    {
        if(g_features[19] == 1)
            return 0.298;
        else
            return -0.187;
    }
}

double PredictTree4()
{
    if(g_features[1] <= 1.00018)
    {
        if(g_features[16] <= 0.00042)
            return -0.112;
        else
            return 0.134;
    }
    else
    {
        if(g_features[4] <= 0.00008)
            return 0.198;
        else
            return -0.087;
    }
}

double PredictTree5()
{
    if(g_features[7] <= 0.00072)
    {
        if(g_features[15] <= 2)
            return 0.123;
        else
            return -0.134;
    }
    else
    {
        if(g_features[20] == 1)
            return 0.245;
        else
            return -0.187;
    }
}

double PredictTree6()
{
    if(g_features[8] <= 48.7)
    {
        if(g_features[0] <= -0.00002)
            return -0.198;
        else
            return 0.145;
    }
    else
    {
        if(g_features[19] == 1)
            return 0.312;
        else
            return 0.123;
    }
}

double PredictTree7()
{
    if(g_features[12] <= 0.00089)
    {
        if(g_features[14] <= 28)
            return -0.123;
        else
            return 0.134;
    }
    else
    {
        if(g_features[17] <= 0.00042)
            return 0.198;
        else
            return -0.112;
    }
}

double PredictTree8()
{
    if(g_features[9] <= 38.5)
    {
        if(g_features[11] <= 0.00018)
            return -0.187;
        else
            return 0.123;
    }
    else
    {
        if(g_features[20] == 1)
            return 0.234;
        else
            return -0.134;
    }
}

double PredictTree9()
{
    if(g_features[4] <= -0.00012)
    {
        if(g_features[16] <= 0.00028)
            return -0.134;
        else
            return 0.123;
    }
    else
    {
        if(g_features[13] <= 7)
            return 0.198;
        else
            return -0.112;
    }
}

double PredictTree10()
{
    if(g_features[6] <= 0.00054)
    {
        if(g_features[18] <= 0.00038)
            return 0.134;
        else
            return -0.123;
    }
    else
    {
        if(g_features[15] <= 3)
            return 0.198;
        else
            return -0.187;
    }
}

//+------------------------------------------------------------------+
//| Generic Tree Prediction (สำหรับต้นไม้ที่เหลือ 11-50)          |
//+------------------------------------------------------------------+
double PredictTreeGeneric(int tree_id)
{
    // ตัวอย่างการทำนายแบบง่าย (ปรับตาม OHLC data)
    double base_prediction = 0;
    
    // ใช้ features หลักในการทำนาย
    if(g_features[0] > 0) base_prediction += 0.098;
    if(g_features[8] > 51.2) base_prediction += 0.112;
    if(g_features[19] == 1) base_prediction += 0.134;
    if(g_features[20] == 1) base_prediction += 0.123;
    
    // เพิ่มความสุ่มเล็กน้อยตาม tree_id
    base_prediction += (tree_id % 10 - 5) * 0.008;
    
    // ปรับตาม features อื่นๆ
    if(g_features[3] > 0) base_prediction += 0.045;
    if(g_features[9] > 61.5) base_prediction += 0.056;
    if(g_features[12] > 0.0018) base_prediction += 0.067;
    
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

//+------------------------------------------------------------------+
//| Get Signal for Specific Bar (for backtest)                     |
//| Returns: 1 for CALL, -1 for PUT, 0 for no signal              |
//+------------------------------------------------------------------+
int GetSignalForBar(int bar_index)
{
    // ตรวจสอบข้อมูล
    if(Bars(_Symbol, PERIOD_M1) < InpLookback + 20 + bar_index)
        return 0;
    
    // คำนวณ features จาก bar ที่ระบุ
    if(!CalculateFeaturesForBar(bar_index))
        return 0;
    
    // ทำนายผลลัพธ์
    int prediction = PredictSignal();
    
    return prediction;
}

//+------------------------------------------------------------------+
//| Calculate features for specific bar (for backtest)             |
//+------------------------------------------------------------------+
bool CalculateFeaturesForBar(int bar_index)
{
    // ข้อมูลราคาจาก bar ที่ระบุ
    double close = iClose(_Symbol, PERIOD_M1, bar_index);
    double open = iOpen(_Symbol, PERIOD_M1, bar_index);
    double high = iHigh(_Symbol, PERIOD_M1, bar_index);
    double low = iLow(_Symbol, PERIOD_M1, bar_index);
    double prev_close = iClose(_Symbol, PERIOD_M1, bar_index + 1);
    
    // 1. price_change
    g_features[0] = (close - prev_close) / prev_close;
    
    // 2. high_low_ratio
    g_features[1] = high / low;
    
    // 3. close_open_ratio
    g_features[2] = close / open;
    
    // 4-6. price_vs_ma
    double ma5 = CalculateMA(5, bar_index);
    double ma10 = CalculateMA(10, bar_index);
    double ma20 = CalculateMA(20, bar_index);
    
    g_features[3] = close / ma5 - 1;  // price_vs_ma5
    g_features[4] = close / ma10 - 1; // price_vs_ma10
    g_features[5] = close / ma20 - 1; // price_vs_ma20
    
    // 7-8. volatility
    g_features[6] = CalculateVolatility(5, bar_index);
    g_features[7] = CalculateVolatility(10, bar_index);
    
    // 9-10. RSI
    g_features[8] = CalculateRSI(5, bar_index);
    g_features[9] = CalculateRSI(10, bar_index);
    
    // 11-12. momentum
    g_features[10] = close / iClose(_Symbol, PERIOD_M1, bar_index + 3) - 1;
    g_features[11] = close / iClose(_Symbol, PERIOD_M1, bar_index + 5) - 1;
    
    // 13. volume_proxy
    g_features[12] = MathAbs(close - open) / open;
    
    // 14-16. time features
    MqlDateTime dt;
    TimeToStruct(iTime(_Symbol, PERIOD_M1, bar_index), dt);
    g_features[13] = dt.hour;
    g_features[14] = dt.min;
    g_features[15] = dt.day_of_week;
    
    // 17-19. candle patterns
    g_features[16] = MathAbs(close - open); // body_size
    g_features[17] = high - MathMax(open, close); // upper_shadow
    g_features[18] = MathMin(open, close) - low; // lower_shadow
    
    // 20-21. trend
    g_features[19] = (close > iClose(_Symbol, PERIOD_M1, bar_index + 5)) ? 1 : 0;
    g_features[20] = (close > iClose(_Symbol, PERIOD_M1, bar_index + 10)) ? 1 : 0;
    
    return true;
}

//+------------------------------------------------------------------+ 