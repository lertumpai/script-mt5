#property copyright "ChatGPT"
#property version   "3.4"
#property strict

#include "../Include/Lertumpai/connector_mt2.mqh"
#include "../Include/Lertumpai/signal/main.mqh"

input int StartHour = 7;
input int EndHour = 21;
input int TimeZone = 7;
input bool StopTrade = false;

input ENUM_TIMEFRAMES timeFrame = PERIOD_M1;

int OnInit()
{
	InitConnectorToMT2();
	
	Print("System trade = ", GetSystemName());
	
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnTick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
    if (StopTrade) return ;
    
    MqlDateTime t; TimeToStruct(TimeCurrent(), t);
    int localHour = (t.hour + TimeZone) % 24;
    if (localHour < StartHour || localHour >= EndHour) return ;
    
    int secondNow = t.sec;
    if (secondNow < 1) return ;

    int minuteNow = t.min;
    if (minuteNow == LastSignalMinute) return ;
   
    CheckPreviousTradeResult();
    PredictSignal();
    
    if (predicted_score == 0 || predicted_score == 0.0) {
       Print("=====SKIP=====");
       return ;
    }
    
    SendMT2Signal(signalName(), predicted_direction);
    LastSignalMinute = minuteNow;
    
    Print("==========");
}

string signalName() {
   return "System["+ GetSystemName() + "]" + "_" + "AmountType["+ GetAmountType() + "]";
}