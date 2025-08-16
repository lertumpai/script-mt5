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

int ExpiryMinutes = 1;
input string SignalName = "sLertumpai";
input string SignalID = "sLertumpai";
input bool EnableLog = false;

input Account IqOptionAccount = NewSorawit;

datetime signalTime;
int LastSignalMinute = 0;
string asset;

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
   mt2trading(asset, dstr, CalculateAmount(), ExpiryMinutes, 0, 0,
			 0, IQOption, finalSigname, curSignalId);
}


// Result Calculation
string prevSignalId = "";
string curSignalId = "";

input int totalWin = 0;
int win = 0;
int loss = 0;
int tie = 0;
int consecutiveWin = 0;
int maxConsecutiveWin = 0;
int consecutiveLoss = 0;
int maxConsecutiveLoss = 0;
Result previousResult = TIE;

void ResetTradeResult() {
   win = 0;
   loss = 0;
   tie = 0;
   consecutiveLoss = 0;
   consecutiveWin = 0;
   maxConsecutiveLoss = 0;
   maxConsecutiveWin = 0;
}

void WinRate() {
   double winrate = win / (win+loss);
   Print("Winrate = ", winrate);
}

void Win() {
   ++win;
   ++consecutiveWin;
   consecutiveLoss=0;
   
   if (consecutiveWin > maxConsecutiveWin) {
      maxConsecutiveWin = consecutiveWin;
   }
   
   previousResult = WIN;
}

void Loss() {
   ++loss;
   ++consecutiveLoss;
   consecutiveWin = 0;
   
   if (consecutiveLoss > maxConsecutiveLoss) {
      maxConsecutiveLoss = consecutiveLoss;
   }
   
   previousResult = LOSS;
}

void Tie() {
   ++tie;
}

void CheckPreviousTradeResult() {
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
         Tie();
         previousResult = TIE;
      }
      else if (result == 1) {
         Win();
      }
      else if (result == 2) {
         Loss();
      }
      
      prevSignalId = "";
   }
}

// Calculate amount
enum AmountType {
   Martingale = 0,
   MartingaleDivided2 = 1
};

input double Payout = 0.8;
input double DefaultAmount = 1.25;
input AmountType amountType = Martingale;

double CalculateAmount() {
   switch (amountType) {
      case Martingale: return calculateMartingale();
      case MartingaleDivided2: return martingaleDivided2();
      default: return DefaultAmount;
   }
}

double calculateMartingale() {
    switch(consecutiveLoss)
     {
      case 0:
         return 1.25;      
      case 1:
         return 2.81;     
      case 2:
         return 6.33;    
      case 3:
         return 14.25;    
      case 4:
         return 32.05;    
      case 5:
         return 72.11;    
      case 6:
         return 163.51;   
      case 7:
         return 368.14;    
      case 8:
         return 828.06;   
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


double accumulateLoss = 0;
double currentAmount = DefaultAmount;

double calculateAmountMartingaleDivided2() {
   if (accumulateLoss == 0) return DefaultAmount;

   double nextAmount = NormalizeDouble((NormalizeDouble(accumulateLoss/2, 2) + NormalizeDouble(currentAmount * (1-Payout), 2)) / Payout, 2);
   return nextAmount < 1 ? DefaultAmount : nextAmount;
}

double martingaleDivided2() {
   if (previousResult == WIN) {
      if (consecutiveWin <= 1) {
         accumulateLoss = NormalizeDouble(accumulateLoss - calculateAmountMartingaleDivided2() * Payout, 2);
      }
      else {
         accumulateLoss = 0;
         currentAmount = calculateAmountMartingaleDivided2();
      }
   }
   else if (previousResult == LOSS) {
      accumulateLoss = NormalizeDouble(accumulateLoss + calculateAmountMartingaleDivided2(), 2);
      currentAmount = calculateAmountMartingaleDivided2();
   }
   
   return currentAmount;
}