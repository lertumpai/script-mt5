#property copyright "ChatGPT"
#property version   "3.4"
#property strict
#property indicator_chart_window
#property indicator_buffers 0

#include "../Include/Lertumpai/candle_v2.mqh"
#include "../Include/Lertumpai/connector_mt2.mqh"

// INPUTS
input int StartHour = 7;
input int EndHour = 21;
input int TimeZone = 7;
input bool StopTrade = false;

input ENUM_TIMEFRAMES timeFrame = PERIOD_M1;

int OnInit()
{
	InitConnectorToMT2();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
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
    if (StopTrade) return 0;
    
    MqlDateTime t; TimeToStruct(TimeCurrent(), t);
    int localHour = (t.hour + TimeZone) % 24;
    if (localHour < StartHour || localHour >= EndHour) return rates_total;
    
    int secondNow = t.sec;
    if (secondNow < 2) return 0;
    
    CalTradeResult();

    int minuteNow = t.min;
    if (minuteNow == LastSignalMinute) return 0;

    double score = PredictSignal();
    Print("score: ", score);
    
    if (score == 0) {
       Print("==========");
       return rates_total;
    }
    
    SendMT2Signal(score, GetSystemName());
    LastSignalMinute = minuteNow;
    
    Print("==========");
    return rates_total;
}

void PrintLog(string msg) {
   if (EnableLog) Print(msg);
}
