//+------------------------------------------------------------------+
//|                                    XGBoostSignalIndicator.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Include XGBoost Signal Library
#include "XGBoostSignalLibrary.mqh"

//--- indicator buffers
double CallBuffer[];
double PutBuffer[];

//--- input parameters
input bool   InpShowArrows = true;     // Show signal arrows
input color  InpCallColor = clrLime;   // CALL signal color
input color  InpPutColor = clrRed;     // PUT signal color
input int    InpArrowSize = 3;         // Arrow size

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // ตรวจสอบ timeframe
    if(Period() != PERIOD_M1)
    {
        Print("ERROR: This indicator is designed for M1 timeframe only!");
        return INIT_FAILED;
    }
    
    // Initialize XGBoost Library
    InitXGBoostLibrary();
    
    // Set indicator buffers
    SetIndexBuffer(0, CallBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, PutBuffer, INDICATOR_DATA);
    
    // Set indicator labels
    PlotIndexSetString(0, PLOT_LABEL, "XGBoost CALL Signal");
    PlotIndexSetString(1, PLOT_LABEL, "XGBoost PUT Signal");
    
    // Set indicator colors
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpCallColor);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpPutColor);
    
    // Set indicator styles
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
    
    // Set arrow codes
    PlotIndexSetInteger(0, PLOT_ARROW, 233); // Up arrow
    PlotIndexSetInteger(1, PLOT_ARROW, 234); // Down arrow
    
    // Set arrow sizes
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, InpArrowSize);
    PlotIndexSetInteger(1, PLOT_LINE_WIDTH, InpArrowSize);
    
    // Set indicator name
    IndicatorSetString(INDICATOR_SHORTNAME, "XGBoost Signal");
    
    Print("=== XGBoost Signal Indicator Started ===");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // ตรวจสอบข้อมูล
    if(rates_total < 20) return 0;
    
    // คำนวณจากแท่งล่าสุด
    int start = prev_calculated;
    if(start == 0) start = 20; // เริ่มจากแท่งที่ 20
    
    // คำนวณสัญญาณสำหรับแต่ละแท่ง
    for(int i = start; i < rates_total; i++)
    {
        // ใช้ Library function
        int signal = GetSignal();
        
        // กำหนดค่าสัญญาณ
        if(signal == 1) // CALL
        {
            CallBuffer[i] = low[i] - (high[i] - low[i]) * 0.1; // ลูกศรขึ้น
            PutBuffer[i] = EMPTY_VALUE;
        }
        else if(signal == -1) // PUT
        {
            PutBuffer[i] = high[i] + (high[i] - low[i]) * 0.1; // ลูกศรลง
            CallBuffer[i] = EMPTY_VALUE;
        }
        else // ไม่มีสัญญาณ
        {
            CallBuffer[i] = EMPTY_VALUE;
            PutBuffer[i] = EMPTY_VALUE;
        }
    }
    
    return(rates_total);
}

//+------------------------------------------------------------------+
//| Get Signal Info Function                                       |
//| Returns: Signal information as string                          |
//+------------------------------------------------------------------+
string GetSignalInfo()
{
    int signal = GetSignal();
    double strength = GetSignalStrength();
    
    string info = "";
    switch(signal)
    {
        case 1:
            info = "CALL Signal - Strength: " + DoubleToString(strength, 3);
            break;
        case -1:
            info = "PUT Signal - Strength: " + DoubleToString(strength, 3);
            break;
        default:
            info = "NO SIGNAL - Strength: " + DoubleToString(strength, 3);
            break;
    }
    
    return info;
}

//+------------------------------------------------------------------+ 