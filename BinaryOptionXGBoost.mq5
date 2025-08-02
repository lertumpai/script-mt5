//+------------------------------------------------------------------+
//|                                           BinaryOptionXGBoost.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input int    InpLookback = 20;        // Lookback period for features
input double InpLotSize = 0.1;        // Lot size
input int    InpMagic = 12345;        // Magic number
input int    InpExpirationMinutes = 5; // Binary option expiration (minutes)
input double InpWinRateThreshold = 0.6; // Win rate threshold (60%)
input bool   InpEnableTrading = false; // Enable actual trading
input int    InpMaxOrders = 1;        // Maximum concurrent orders

//--- global variables
double g_features[21];  // 21 features
int g_last_signal = 0; // 0=no signal, 1=CALL, 2=PUT
datetime g_last_signal_time = 0;
int g_order_count = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== Binary Option XGBoost EA Started ===");
    Print("Features: 21");
    Print("Win Rate Threshold: ", InpWinRateThreshold * 100, "%");
    Print("Trading Enabled: ", InpEnableTrading ? "Yes" : "No");
    
    // ตรวจสอบ timeframe
    if(Period() != PERIOD_M1)
    {
        Print("ERROR: This EA is designed for M1 timeframe only!");
        return INIT_FAILED;
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== Binary Option XGBoost EA Stopped ===");
    Print("Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{
    // ตรวจสอบว่าเป็นเวลาที่เหมาะสมหรือไม่
    if(!IsTradeAllowed()) return;
    
    // ตรวจสอบจำนวน orders
    if(g_order_count >= InpMaxOrders) return;
    
    // ตรวจสอบเวลา (ไม่ส่งสัญญาณซ้ำในเวลาเดียวกัน)
    datetime current_time = TimeCurrent();
    if(current_time == g_last_signal_time) return;
    
    // คำนวณ features
    if(!CalculateFeatures())
        return;
    
    // ทำนายผลลัพธ์
    int prediction = PredictSignal();
    
    // ส่งสัญญาณ
    if(prediction != g_last_signal && prediction != 0)
    {
        g_last_signal = prediction;
        g_last_signal_time = current_time;
        
        if(prediction == 1)
        {
            Print("=== SIGNAL: CALL ===");
            if(InpEnableTrading)
                PlaceBinaryOption(ORDER_TYPE_BUY, "CALL");
        }
        else if(prediction == 2)
        {
            Print("=== SIGNAL: PUT ===");
            if(InpEnableTrading)
                PlaceBinaryOption(ORDER_TYPE_SELL, "PUT");
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate technical features                                    |
//+------------------------------------------------------------------+
bool CalculateFeatures()
{
    if(Bars(_Symbol, PERIOD_M1) < InpLookback + 20)
        return false;
    
    // ข้อมูลราคาปัจจุบัน
    double close = iClose(_Symbol, PERIOD_M1, 0);
    double open = iOpen(_Symbol, PERIOD_M1, 0);
    double high = iHigh(_Symbol, PERIOD_M1, 0);
    double low = iLow(_Symbol, PERIOD_M1, 0);
    double prev_close = iClose(_Symbol, PERIOD_M1, 1);
    
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
    g_features[10] = close / iClose(_Symbol, PERIOD_M1, 3) - 1;
    g_features[11] = close / iClose(_Symbol, PERIOD_M1, 5) - 1;
    
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
    g_features[19] = (close > iClose(_Symbol, PERIOD_M1, 5)) ? 1 : 0;
    g_features[20] = (close > iClose(_Symbol, PERIOD_M1, 10)) ? 1 : 0;
    
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
        sum += iClose(_Symbol, PERIOD_M1, i);
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
        mean += iClose(_Symbol, PERIOD_M1, i);
    }
    mean /= period;
    
    double variance = 0;
    for(int i = 0; i < period; i++)
    {
        double diff = iClose(_Symbol, PERIOD_M1, i) - mean;
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
        double change = iClose(_Symbol, PERIOD_M1, i-1) - iClose(_Symbol, PERIOD_M1, i);
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
//| XGBoost Prediction Function                                   |
//+------------------------------------------------------------------+
int PredictSignal()
{
    // คำนวณผลลัพธ์จากต้นไม้ทั้งหมด (50 ต้นไม้)
    double prediction = 0;
    
    // ต้นไม้ที่ 1-5 (ตัวอย่าง)
    prediction += PredictTree1();
    prediction += PredictTree2();
    prediction += PredictTree3();
    prediction += PredictTree4();
    prediction += PredictTree5();
    
    // ต้นไม้ที่ 6-50 (simplified)
    for(int i = 6; i <= 50; i++)
    {
        prediction += PredictTreeGeneric(i);
    }
    
    // แปลงเป็นความน่าจะเป็น
    double probability = 1.0 / (1.0 + MathExp(-prediction));
    
    // Debug info
    if(probability > 0.5)
    {
        Print("Probability: ", probability, " -> CALL");
    }
    else
    {
        Print("Probability: ", probability, " -> PUT");
    }
    
    // ส่งสัญญาณตาม threshold
    if(probability > InpWinRateThreshold)
        return 1; // CALL
    else
        return 2; // PUT
}

//+------------------------------------------------------------------+
//| Tree Prediction Functions (ตัวอย่าง 5 ต้นแรก)                |
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

//+------------------------------------------------------------------+
//| Generic Tree Prediction (สำหรับต้นไม้ที่เหลือ)               |
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
    
    return base_prediction;
}

//+------------------------------------------------------------------+
//| Place Binary Option Order                                     |
//+------------------------------------------------------------------+
void PlaceBinaryOption(ENUM_ORDER_TYPE order_type, string signal_type)
{
    Print("Placing ", signal_type, " order...");
    
    // ตัวอย่างการวาง order (ต้องปรับตาม broker)
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = InpLotSize;
    request.type = order_type;
    request.price = (order_type == ORDER_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request.deviation = 5;
    request.magic = InpMagic;
    request.comment = "XGBoost " + signal_type;
    
    if(OrderSend(request, result))
    {
        Print("Order placed successfully: ", signal_type);
        g_order_count++;
    }
    else
    {
        Print("Order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Check and update order count                                  |
//+------------------------------------------------------------------+
void OnTrade()
{
    // อัพเดทจำนวน orders ที่เปิดอยู่
    g_order_count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(OrderGetTicket(i)))
        {
            if(OrderGetInteger(ORDER_MAGIC) == InpMagic)
            {
                g_order_count++;
            }
        }
    }
}

//+------------------------------------------------------------------+ 