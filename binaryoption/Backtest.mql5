//+------------------------------------------------------------------+
//|     EURUSD Hybrid Bot - Trend & Sideway (MQL5 Example)           |
//+------------------------------------------------------------------+
#property copyright "ChatGPT"
#property version   "1.0"
#property strict

#include "../Include/Lertumpai/xgboost.mqh"

//--- Inputs
input double StartBalance      = 100.0;
input double PayoutPercent     = 80.0;
input int StartHour            = 8;
input int EndHour              = 23;
input int TimeZone             = 7;
input bool EnableLog           = true;
input double Min_BB_Width      = 0.0050;
input double Trend_BB_Width    = 0.0080;
input int Cooldown_Lose        = 3;
input int Cooldown_Minutes     = 30;

double balance;
double lotSize;
int lose_streak = 0;
datetime cooldown_until = 0;
datetime lastTradeTime = 0;
string version = "1.0.4";

//--- Win/Lose Tracking
double totalWin = 0;
double totalLose = 0;
int maxWinStep = 0;
int maxLoseStep = 0;
int currentWinStep = 0;
int currentLoseStep = 0;
int tradeCount = 0;


void OnInit() {
   balance = StartBalance;
}

void OnDeinit(const int reason)
{
    PrintLog(StringFormat("Backtest Ended | Final Balance = %.2f", balance));
    int totalTrade = (int)(totalWin + totalLose);
    double winrate = (totalTrade > 0) ? (totalWin / totalTrade) * 100.0 : 0.0;
    Print("Total trade: ", totalTrade, ", win rate: ", winrate, "%");
    Print("Max win step = ", maxWinStep);
    Print("Max lose step = ", maxLoseStep);
    Print("Version: ", version);
}

int step = 1;
//+------------------------------------------------------------------+
//| Main Tick Function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   if (step > 9) return;

    datetime currentTime = iTime(_Symbol, PERIOD_M1, 0);
    if(currentTime == lastTradeTime) return;
    lastTradeTime = currentTime;

    MqlDateTime t;
    TimeToStruct(currentTime, t);
    int localHour = (t.hour + TimeZone) % 24;
    if (localHour < StartHour || localHour >= EndHour) return;

    int signal = GetSignal();

    bool result = SimulateTrade(signal);
    string dstr = (signal == 1) ? "CALL" : "PUT";
    lotSize = CalcLotSize(step);
    tradeCount++;
    Print("Trade round = ", tradeCount);

    if(result) {
        double profit = lotSize * (PayoutPercent / 100.0);
        balance += profit;
        PrintLog(StringFormat("WIN | Dir=%s | Lot=%.2f | Profit=%.2f | Balance=%.2f",
                dstr, lotSize, profit, balance));
                
        totalWin++;
        currentWinStep++;
        currentLoseStep = 0;
        if (currentWinStep > maxWinStep) maxWinStep = currentWinStep;
        
        step = 1;
    }
    else {
        balance -= lotSize;
        PrintLog(StringFormat("STEP[%d]: LOSS | Dir=%s | Lot=%.2f | Loss=%.2f | Balance=%.2f",
                step, dstr, lotSize, lotSize, balance));
                
        totalLose++;
        currentWinStep = 0;
        currentLoseStep++;
        if (currentLoseStep > maxLoseStep) maxLoseStep = currentLoseStep;
        
        step++;
    }
    
    Print("===============");
}



bool SimulateTrade(int direction)
{
    double open = iOpen(_Symbol, PERIOD_M1, 1);
    double close = iClose(_Symbol, PERIOD_M1, 1);

    if(direction == 1 && close > open) return true;  // CALL win
    if(direction == -1 && close < open) return true; // PUT win
    return false;
}

void PrintLog(string msg) { if (EnableLog) Print(msg); }

double CalcLotSize(int current_step)
  {
      switch(current_step)
     {
      case 1:
         return 1.25;      // ไม้ 1
      case 2:
         return 2.81;      // ไม้ 2
      case 3:
         return 6.33;      // ไม้ 3
      case 4:
         return 14.25;     // ไม้ 4
      case 5:
         return 32.05;     // ไม้ 5
      case 6:
         return 72.11;     // ไม้ 6
      case 7:
         return 163.51;    // ไม้ 7
      case 8:
         return 368.14;    // ไม้ 8
      case 9:
         return 828.06;    // ไม้ 9
     }
     
     return 0;
  }

