#include "./date.mqh"

enum brokers {
	All = 0,
	IQOption = 1,
	Binary = 2,
	Spectre = 3,
	Alpari = 4,
	InstaBinary = 5,
	OptionField = 6,
	CLMForex = 7,
	DukasCopy = 8,
	GCOption = 9,
	StrategyTester = 10,
	CapitalCore = 11,
	PocketOption = 12,
	Bitness = 13
};

enum martingale {
	NoMartingale = 0,
	OnNextExpiry = 1,
	OnNextSignal = 2,
	Anti_OnNextExpiry = 3,
	Anti_OnNextSignal = 4,
	OnNextSignal_Global= 5,
	Anti_OnNextSignal_Global = 6
};

enum Account {
   NewSorawit = 0,
   slertumpai = 1
};
	
enum Result {
	TIE = 0,
	WIN = 1,
	LOSS = 2
};

//----- Import MT2Trading library
#import "mt2trading_library.ex5" 
	bool mt2trading (string symbol, string direction, double amount, int expiryMinutes, martingale martingaleType, int martingaleSteps, double martingaleCoef, brokers myBroker, string signalName, string signalid);
	int traderesult (string signalid);
#import

input int ExpiryMinutes = 1;
input string SignalName = "sLertumpai";
input string SignalID = "sLertumpai";
input bool EnableLog = false;

input Account IqOptionAccount = NewSorawit;

input brokers Broker = All;
input martingale MartingaleType = NoMartingale;    // Martingale
input int MartingaleSteps = 9;                     // Martingale Steps
input double MartingaleCoef = 2.0;                 // Martingale Coefficient

datetime signalTime;
int LastSignalMinute = 0;
string asset;

string prevSignalId = "";
string curSignalId = "";

bool IsResetResult = false;
input int totalWin = 0;
int win = 0;
int loss = 0;
int tie = 0;
int consecutiveWin = 0;
int maxConsecutiveWin = 0;
int consecutiveLoss = 0;
int maxConsecutiveLoss = 0;

string AccountToString(Account account)
{
   switch(account)
   {
      case NewSorawit:   return "new-sorawit";
      case slertumpai:   return "slertumpai";
      default:          return "UNKNOWN";
   }
}

string GetSignalId() {
   return NowDateTimeMinute() + "_" + AccountToString(IqOptionAccount);
}

void InitConnectorToMT2() {
   //Initialize the time flag
	signalTime = TimeCurrent();
	if (StringLen(Symbol()) >= 6)
		asset = StringSubstr(Symbol(),0,6);
	else
		asset = Symbol();
}

void SendMT2Signal(double score, string systemTradeName)
{
   string dstr = (score >= 0) ? "CALL" : "PUT";
   string finalSigname = "System[" + systemTradeName + "]" + "_" + dstr;
   string dateTime = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   Print(dstr, " Signal at ", dateTime);
   mt2trading(asset, dstr, calculateAmount(), ExpiryMinutes, MartingaleType, MartingaleSteps,
			 MartingaleCoef, Broker, finalSigname, curSignalId);
}

void ResetResult() {
   win = 0;
   loss = 0;
   tie = 0;
   consecutiveLoss = 0;
   consecutiveWin = 0;
   maxConsecutiveLoss = 0;
   maxConsecutiveWin = 0;
   IsResetResult = true;
}

input double Payout = 0.7;
input double DefaultAmount = 1.25;
double accumulateLoss = 0;

double calculateAmount() {
    switch(consecutiveLoss)
     {
      case 0:
         return 1.25;      // ไม้ 1
      case 1:
         return 2.81;      // ไม้ 2
      case 2:
         return 6.33;      // ไม้ 3
      case 3:
         return 14.25;     // ไม้ 4
      case 4:
         return 32.05;     // ไม้ 5
      case 5:
         return 72.11;     // ไม้ 6
      case 6:
         return 163.51;    // ไม้ 7
      case 7:
         return 368.14;    // ไม้ 8
      case 8:
         return 828.06;    // ไม้ 9
      case 9:
         return 1847.36;   
      case 10:
         return 4156.57;   
      case 11:
         return 9352.28;
      default:
         return 1.25;
     }
     
     return 1.25;
}

void CalTradeResult() {
   string signalId = GetSignalId();
   
   if (signalId != curSignalId) {
      prevSignalId = curSignalId;
      curSignalId = signalId;
   }
   
   if (prevSignalId != "") {
      int result = traderesult(prevSignalId);
      while (result < 0) {
         Sleep(200);
         result = traderesult(prevSignalId);         
      }
      
      if (result == 0) {
         ++tie;
      }
      else if (result == 1) {
         ++win;
         ++consecutiveWin;
         consecutiveLoss=0;
      }
      else if (result == 2) {
         ++loss;
         ++consecutiveLoss;
         consecutiveWin = 0;
      }
      
      prevSignalId = "";
   }
}