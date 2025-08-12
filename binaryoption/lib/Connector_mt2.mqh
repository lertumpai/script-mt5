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

input double TradeAmount = 1.0;
input int ExpiryMinutes = 1;
input string SignalName = "sLertumpai";
input string SignalID = "sLertumpai";
input bool EnableLog = false;

input string IqOptionAccount = "";

input brokers Broker = All;
input martingale MartingaleType = OnNextSignal;    // Martingale
input int MartingaleSteps = 9;                     // Martingale Steps
input double MartingaleCoef = 2.0;                 // Martingale Coefficient

datetime signalTime;
int LastSignalMinute = 0;
string asset;

string prevSignalId = "";
string curSignalId = "";

input int totalWin = 0;
int win = 0;
int loss = 0;
int tie = 0;

string GetSignalId() {
   return NowDateTimeMinute() + "_" + IqOptionAccount;
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
   mt2trading(asset, dstr, TradeAmount, ExpiryMinutes, MartingaleType, MartingaleSteps,
			 MartingaleCoef, Broker, finalSigname, GetSignalId());
}

void ResetResult() {
   win = 0;
   loss = 0;
   tie = 0;
}

bool IsWin() {
   return win >= totalWin;
}

void CheckTradeResult() {
   string signalId = GetSignalId();
   
   if (signalId != curSignalId) {
      prevSignalId = curSignalId;
      curSignalId = signalId;
   }
   
   int result = traderesult(prevSignalId);
   if (prevSignalId != "" && result != -1) {
      Print(win, loss);
      if (result == 0) ++tie;
      else if (result == 1) ++win;
      else if (result == 2) ++loss;
      
      prevSignalId = "";
      Print("win=", win, ", loss=", loss, ", tie=", tie);
   }
}