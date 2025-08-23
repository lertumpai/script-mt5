#property copyright "ChatGPT"
#property version   "3.4"
#property strict

#include "../Include/Lertumpai/connector_mt2.mqh"
#include "../Include/Lertumpai/signal/main.mqh"
#include "../Include/Lertumpai/signal/type.mqh"
#include "../Include/Lertumpai/api.mqh"

input int StartHour = 7;
input int EndHour = 21;
input int TimeZone = 7;
input bool StopTrade = false;

input ENUM_TIMEFRAMES timeFrame = PERIOD_M1;

int OnInit()
{
	InitConnectorToMT2();
	
	Print("System trade = ", GetSignalName());
	
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
    
    
    string signalName = GetSignalName();
   
    CheckPreviousTradeResult(signalName);
    Decision decision;
    decision = PredictSignal();
    
    CalculatedAmount calculatedAmount;
    calculatedAmount = CalculateAmount();
    
    if (decision.direction != "NONE") {
      SendMT2Signal(signalName, decision.direction, calculatedAmount.amount, calculatedAmount.curSignalId);
    }
    
    UpsertIqMonitor(signalName, calculatedAmount.amount, decision.score, decision.confidence, consecutiveLoss, decision.direction, calculatedAmount.curSignalId);
    
    LastSignalMinute = minuteNow;
    Print("==========");
}

string GetSignalName() {
   return "System["+ GetSystemName() + "]" + "_" + "AmountType["+ GetAmountType() + "]";
}