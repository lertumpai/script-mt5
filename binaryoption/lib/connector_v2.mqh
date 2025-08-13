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
input martingale MartingaleType = OnNextSignal;    // Martingale
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
   mt2trading(asset, dstr, currentAmount, ExpiryMinutes, MartingaleType, MartingaleSteps,
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

bool IsWin() {
   return win >= totalWin;
}

void CheckTradeResult() {
   int result = traderesult(curSignalId);
   if (result != -1) {
      if (result == 0) {
         ++tie;
      }
      else if (result == 1) {
         ++win;
         ++maxConsecutiveWin;
         if (consecutiveLoss > maxConsecutiveLoss) {
            maxConsecutiveLoss = consecutiveLoss;
         }
         consecutiveLoss = 0;
         curSignalId = GetSignalId();
      }
      else if (result == 2) {
         ++loss;
         ++maxConsecutiveLoss;
         if (consecutiveWin > maxConsecutiveWin) {
            maxConsecutiveWin = consecutiveWin;
         }
         consecutiveWin = 0;
      }
      
      Print("win=", win, ", loss=", loss);
      Print("consecutiveWin=", consecutiveWin, ", consecutiveLoss=", consecutiveLoss);
      Print("maxConsecutiveWin=", maxConsecutiveWin, ", maxConsecutiveLoss=", maxConsecutiveLoss);
   }
}

input double Payout = 0.7;
input double DefaultAmount = 1.25;
double accumulateLoss = 0;
double currentAmount = DefaultAmount;

double calculateAmount() {
   if (accumulateLoss == 0) return DefaultAmount;

   double nextAmount = NormalizeDouble((NormalizeDouble(accumulateLoss/2, 2) + NormalizeDouble(currentAmount * 0.15, 2)) / Payout, 2);
   return nextAmount < 1 ? DefaultAmount : nextAmount;
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
         if (consecutiveWin == 1) {
            accumulateLoss = NormalizeDouble(accumulateLoss - calculateAmount() * Payout, 2);
         }
         else if (consecutiveWin >=2 && accumulateLoss > 0) {
            accumulateLoss = 0;
            currentAmount = calculateAmount();
         }
         Print("Win: ", "accumulateLoss=", accumulateLoss, ", currentAmount=", currentAmount);
      }
      else if (result == 2) {
         ++loss;
         consecutiveWin = 0;
         accumulateLoss = NormalizeDouble(accumulateLoss + calculateAmount(), 2);
         currentAmount = calculateAmount();
         Print("Loss: ", "accumulateLoss=", accumulateLoss, ", currentAmount=", currentAmount);
      }
      
      prevSignalId = "";
   }
}