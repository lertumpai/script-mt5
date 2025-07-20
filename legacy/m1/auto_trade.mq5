//+------------------------------------------------------------------+
//| EURUSD_M1_10PercentAntiFake + MT2TradingLibrary (split logic)    |
//+------------------------------------------------------------------+

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
	
enum result {
	TIE = 0,
	WIN = 1,
	LOSS = 2
};

#property copyright "ChatGPT"
#property version   "3.4"
#property strict
#property indicator_chart_window
#property indicator_buffers 0

//----- Import MT2Trading library
#import "mt2trading_library.ex5" 
	bool mt2trading (string symbol, string direction, double amount, int expiryMinutes, martingale martingaleType, int martingaleSteps, double martingaleCoef, brokers myBroker, string signalName, string signalid);
	int traderesult (string signalid);
#import

// INPUTS
input int StartHour = 7;
input int EndHour = 21;
input int TimeZone = 7;
input double TradeAmount = 1.0;
input int ExpiryMinutes = 1;
input string SignalName = "sLertumpai";
input string SignalID = "sLertumpai";

double SignalBuffer[];

input brokers Broker = All;
input martingale MartingaleType = NoMartingale;    // Martingale
input int MartingaleSteps = 2;                     // Martingale Steps
input double MartingaleCoef = 2.0;                 // Martingale Coefficient

datetime signalTime;
string signalID;
int LastSignalMinute = 0;
string asset;


int ema50_handle, ema200_handle, rsi_handle, macd_handle, stoch_handle, bb_handle, adx_handle, willr_handle;

int OnInit()
{
	//Initialize the time flag
	signalTime = TimeCurrent();
	if (StringLen(Symbol()) >= 6)
		asset = StringSubstr(Symbol(),0,6);
	else
		asset = Symbol();
		
   ema50_handle  = iMA(NULL, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
   ema200_handle = iMA(NULL, PERIOD_M1, 200, 0, MODE_EMA, PRICE_CLOSE);
   rsi_handle    = iRSI(NULL, PERIOD_M1, 14, PRICE_CLOSE);
   macd_handle   = iMACD(NULL, PERIOD_M1, 12, 26, 9, PRICE_CLOSE);
   stoch_handle  = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   bb_handle     = iBands(NULL, PERIOD_M1, 20, 2.0, 0, PRICE_CLOSE);
   adx_handle    = iADX(NULL, PERIOD_M1, 14);
   willr_handle  = iWPR(NULL, PERIOD_M1, 14);
   
   if(ema50_handle==INVALID_HANDLE || ema200_handle==INVALID_HANDLE || rsi_handle==INVALID_HANDLE || 
      macd_handle==INVALID_HANDLE || stoch_handle==INVALID_HANDLE || bb_handle==INVALID_HANDLE || 
      adx_handle==INVALID_HANDLE || willr_handle==INVALID_HANDLE)
   {
      Print("Error: One or more handles failed to create!");
      return INIT_FAILED;
   }

		
	SetIndexBuffer(0, SignalBuffer, INDICATOR_DATA);
   PlotIndexSetString(0,PLOT_LABEL,"SignalBuffer");
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

    MqlDateTime t; TimeToStruct(TimeCurrent(), t);
    int localHour = (t.hour + TimeZone) % 24;
    if (localHour < StartHour || localHour >= EndHour) return rates_total;

    int minuteNow = t.min;
    if (minuteNow == LastSignalMinute) return 0; // ไม่ส่งซ้ำ

    int latestBar = rates_total - 2;
    int direction = GetMajorityVoteSignalM1();
    Print("Latest direction = ", direction);
    
    SignalBuffer[latestBar] = direction;

    if (direction != 0) SendMT2Signal(direction, "Direction");
    LastSignalMinute = minuteNow;
    return rates_total;
}

void SendMT2Signal(int direction, string sigName)
{
   string finalSigname = SignalName + "_" + sigName;
   string dstr = (direction == 1) ? "CALL" : "PUT";
   Print(dstr, " Signal at ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
   mt2trading(asset, dstr, TradeAmount, ExpiryMinutes, MartingaleType, MartingaleSteps,
			 MartingaleCoef, Broker, finalSigname, signalID);
}

//+------------------------------------------------------------------+
//| Majority Vote 7 Indicators (M1) for MT5                         |
//| Return: 1 = Call, -1 = Put, 0 = No Trade                         |
//+------------------------------------------------------------------+
int GetMajorityVoteSignalM1()
  {
   int votes_up = 0, votes_down = 0;
   int index = 1;

   // --- EMA50 & EMA200
   double ema50[], ema200[];
   if(CopyBuffer(ema50_handle, 0, index, 1, ema50) > 0 && CopyBuffer(ema200_handle, 0, index, 1, ema200) > 0)
     {
      if(ema50[0] > ema200[0]) votes_up++;
      else if(ema50[0] < ema200[0]) votes_down++;
     }

   // --- RSI(14)
   double rsi_val[];
   if(CopyBuffer(rsi_handle, 0, index, 1, rsi_val) > 0)
     {
      if(rsi_val[0] > 55) votes_up++;
      else if(rsi_val[0] < 45) votes_down++;
     }

   // --- MACD(12,26,9)
   double macd_main[], macd_signal[];
   if(CopyBuffer(macd_handle, 0, index, 1, macd_main) > 0 && CopyBuffer(macd_handle, 1, index, 1, macd_signal) > 0)
     {
      if(macd_main[0] > macd_signal[0]) votes_up++;
      else if(macd_main[0] < macd_signal[0]) votes_down++;
     }

   // --- Stochastic(14,3,3)
   double k[], d[];
   if(CopyBuffer(stoch_handle, 0, index, 1, k) > 0 && CopyBuffer(stoch_handle, 1, index, 1, d) > 0)
     {
      if(k[0] > d[0] && k[0] > 50) votes_up++;
      else if(k[0] < d[0] && k[0] < 50) votes_down++;
     }

   // --- Bollinger Bands(20,2)
   double bb_middle[];
   if(CopyBuffer(bb_handle, 1, index, 1, bb_middle) > 0)
     {
      double close_price = iClose(NULL, PERIOD_M1, index);
      if(close_price > bb_middle[0]) votes_up++;
      else if(close_price < bb_middle[0]) votes_down++;
     }

   // --- ADX(14)
   double adx_val[], plusDI[], minusDI[];
   if(CopyBuffer(adx_handle, 0, index, 1, adx_val) > 0 && CopyBuffer(adx_handle, 1, index, 1, plusDI) > 0 && CopyBuffer(adx_handle, 2, index, 1, minusDI) > 0)
     {
      if(adx_val[0] > 20)
        {
         if(plusDI[0] > minusDI[0]) votes_up++;
         else if(minusDI[0] > plusDI[0]) votes_down++;
        }
     }

   // --- Williams %R
   double willr_val[];
   if(CopyBuffer(willr_handle, 0, index, 1, willr_val) > 0)
     {
      if(willr_val[0] > -50) votes_up++;
      else if(willr_val[0] < -50) votes_down++;
     }

   Print("votes_up=", votes_up," vs votes_down=",votes_down);
   if(votes_up > votes_down) return 1;      // Call
   if(votes_down > votes_up) return -1;     // Put
   return 0;                                // No Trade
  }

