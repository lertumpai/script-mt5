//+------------------------------------------------------------------+
//| Binary Option M1 Pro EA - Sustainable Trading System            |
//+------------------------------------------------------------------+
#property copyright "Binary M1 Pro System"
#property version   "3.0"
#property strict
#property indicator_chart_window
#property indicator_buffers 0

//----- Import MT2Trading library
#import "mt2trading_library.ex5"
	bool mt2trading(string symbol, string direction, double amount, int expiryMinutes, 
					int martingaleType, int martingaleSteps, double martingaleCoef, 
					int myBroker, string signalName, string signalid);
	int traderesult(string signalid);
#import

//--- Enums
enum brokers {
	All = 0, IQOption = 1, Binary = 2, Spectre = 3, Alpari = 4,
	InstaBinary = 5, OptionField = 6, CLMForex = 7, DukasCopy = 8,
	GCOption = 9, StrategyTester = 10, CapitalCore = 11, PocketOption = 12,
	Bitness = 13, Quotex = 14
};

enum martingale {
	NoMartingale = 0, OnNextExpiry = 1, OnNextSignal = 2,
	Anti_OnNextExpiry = 3, Anti_OnNextSignal = 4,
	OnNextSignal_Global = 5, Anti_OnNextSignal_Global = 6
};

enum MarketRegime {
	TRENDING_UP, TRENDING_DOWN, SIDEWAYS, VOLATILE
};

//--- Input Parameters
input group "=== Risk Management ==="
input double BaseAmount = 10.0;           // Base trade amount ($)
input double MaxRiskPercent = 0.02;       // Max risk per trade (2%)
input int MaxMartingaleSteps = 5;         // Max martingale steps
input double DailyLossLimit = 0.10;       // Daily loss limit (10%)
input double DailyProfitTarget = 0.05;    // Daily profit target (5%)

input group "=== Signal Settings ==="
input double MinSignalConfidence = 70.0;  // Minimum signal confidence (%)
input bool UseMultiTimeframe = true;      // Multi-timeframe analysis
input bool UseVolumeFilter = true;        // Volume confirmation
input bool UseNewsFilter = true;          // News avoidance
input bool UseMarketRegimeFilter = true;  // Market regime detection

input group "=== Trading Hours ==="
input int StartHour = 8;                  // Trading start (GMT)
input int EndHour = 22;                   // Trading end (GMT)
input bool TradeLondonSession = true;     // London session (8-17 GMT)
input bool TradeNewYorkSession = true;    // New York session (13-22 GMT)
input bool AvoidNews = true;              // Avoid major news times

input group "=== MT2Trading ==="
input brokers TargetBroker = IQOption;    // Target broker
input string SignalName = "BinaryM1Pro";  // Signal name
input string SignalPrefix = "BM1";        // Signal ID prefix
input martingale MartingaleType = NoMartingale; // Martingale (handled internally)

input group "=== Indicator Settings ==="
input int EMA_Fast = 21;                  // EMA Fast period
input int EMA_Slow = 55;                  // EMA Slow period
input int RSI_Period = 14;                // RSI period
input int MACD_Fast = 12;                 // MACD Fast EMA
input int MACD_Slow = 26;                 // MACD Slow EMA
input int MACD_Signal = 9;                // MACD Signal period
input int Stoch_K = 14;                   // Stochastic %K
input int Stoch_D = 3;                    // Stochastic %D
input int BB_Period = 20;                 // Bollinger Bands period
input double BB_Deviation = 2.0;          // Bollinger Bands deviation
input int ADX_Period = 14;                // ADX period

//--- Global Variables
struct BinarySignal {
	int direction;           // 1=CALL, -1=PUT, 0=No Trade
	double confidence;       // 0-100%
	double signalStrength;   // Combined score
	bool isHighQuality;      // Quality flag
	string reason;           // Signal reason
	datetime timestamp;      // Signal time
};

struct TradeStats {
	int totalTrades;
	int winTrades;
	int lossTrades;
	double totalProfit;
	double totalLoss;
	double dailyPnL;
	int currentStep;
	int consecutiveLosses;
	datetime lastTradeTime;
	datetime dayStartTime;
};

struct DailyLimits {
	double maxDailyLoss;
	double maxDailyProfit;
	int maxDailyTrades;
	int maxConsecutiveLosses;
	bool dailyTargetReached;
	bool dailyLossLimitReached;
};

//--- Indicator Handles
int ema_fast_handle, ema_slow_handle;
int ema_fast_m5_handle, ema_slow_m5_handle;
int rsi_handle, macd_handle, stoch_handle;
int bb_handle, adx_handle, atr_handle;
int volume_ma_handle;

//--- Global Objects
TradeStats g_stats;
DailyLimits g_limits;
string g_asset;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
	Print("=== Binary Option M1 Pro EA Initializing ===");
	
	// Initialize asset name
	if(StringLen(Symbol()) >= 6)
		g_asset = StringSubstr(Symbol(), 0, 6);
	else
		g_asset = Symbol();
	
	// Initialize indicators
	if(!InitializeIndicators()) {
		Print("ERROR: Failed to initialize indicators");
		return INIT_FAILED;
	}
	
	// Initialize statistics
	InitializeStats();
	
	// Initialize daily limits
	InitializeDailyLimits();
	
	// Set timer for daily reset and monitoring
	EventSetTimer(60); // Check every minute
	
	Print("=== Binary Option M1 Pro EA Initialized Successfully ===");
	Print("Asset: ", g_asset);
	Print("Base Amount: $", BaseAmount);
	Print("Max Risk: ", MaxRiskPercent * 100, "%");
	Print("Min Confidence: ", MinSignalConfidence, "%");
	Print("Target Broker: ", EnumToString(TargetBroker));
	
	return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
	EventKillTimer();
	PrintFinalStats();
	Print("=== Binary Option M1 Pro EA Deinitialized ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
	// Check if new bar
	static datetime lastBarTime = 0;
	datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);
	if(currentBarTime == lastBarTime) return;
	lastBarTime = currentBarTime;
	
	// Check daily limits first
	if(!CheckDailyLimits()) return;
	
	// Check trading hours
	if(!IsValidTradingTime()) return;
	
	// Check news filter
	if(UseNewsFilter && IsNewsTime()) return;
	
	// Generate signal
	BinarySignal signal = GenerateM1Signal();
	
	// Validate signal
	if(!ValidateSignal(signal)) return;
	
	// Calculate trade amount
	double tradeAmount = CalculateTradeAmount();
	if(tradeAmount <= 0) return;
	
	// Send signal to MT2Trading
	if(SendBinarySignal(signal, tradeAmount)) {
		RecordTrade(signal, tradeAmount);
		PrintTradeInfo(signal, tradeAmount);
	}
}

//+------------------------------------------------------------------+
//| Timer function for monitoring and daily reset                    |
//+------------------------------------------------------------------+
void OnTimer() {
	// Check for new day
	MqlDateTime dt;
	TimeToStruct(TimeCurrent(), dt);
	
	static int lastDay = -1;
	if(dt.day != lastDay) {
		ResetDailyCounters();
		lastDay = dt.day;
		Print("=== New Trading Day Started ===");
	}
	
	// Monitor performance every hour
	static int lastHour = -1;
	if(dt.hour != lastHour) {
		PrintHourlyStats();
		CheckEmergencyStop();
		lastHour = dt.hour;
	}
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                         |
//+------------------------------------------------------------------+
bool InitializeIndicators() {
	// M1 indicators
	ema_fast_handle = iMA(Symbol(), PERIOD_M1, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
	ema_slow_handle = iMA(Symbol(), PERIOD_M1, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
	rsi_handle = iRSI(Symbol(), PERIOD_M1, RSI_Period, PRICE_CLOSE);
	macd_handle = iMACD(Symbol(), PERIOD_M1, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
	stoch_handle = iStochastic(Symbol(), PERIOD_M1, Stoch_K, Stoch_D, 3, MODE_SMA, STO_LOWHIGH);
	bb_handle = iBands(Symbol(), PERIOD_M1, BB_Period, BB_Deviation, 0, PRICE_CLOSE);
	adx_handle = iADX(Symbol(), PERIOD_M1, ADX_Period);
	atr_handle = iATR(Symbol(), PERIOD_M1, 14);
	volume_ma_handle = iMA(Symbol(), PERIOD_M1, 20, 0, MODE_SMA, PRICE_VOLUME);
	
	// M5 trend filters
	ema_fast_m5_handle = iMA(Symbol(), PERIOD_M5, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
	ema_slow_m5_handle = iMA(Symbol(), PERIOD_M5, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
	
	// Check all handles
	if(ema_fast_handle == INVALID_HANDLE || ema_slow_handle == INVALID_HANDLE ||
	   rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE ||
	   stoch_handle == INVALID_HANDLE || bb_handle == INVALID_HANDLE ||
	   adx_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE ||
	   volume_ma_handle == INVALID_HANDLE ||
	   ema_fast_m5_handle == INVALID_HANDLE || ema_slow_m5_handle == INVALID_HANDLE) {
		return false;
	}
	
	return true;
}

//+------------------------------------------------------------------+
//| Generate M1 Binary Option Signal                                 |
//+------------------------------------------------------------------+
BinarySignal GenerateM1Signal() {
	BinarySignal signal;
	signal.direction = 0;
	signal.confidence = 0.0;
	signal.signalStrength = 0.0;
	signal.isHighQuality = false;
	signal.reason = "No Signal";
	signal.timestamp = TimeCurrent();
	
	// Calculate component scores
	double trendScore = GetTrendScore();           // -40 to +40
	double momentumScore = GetMomentumScore();     // -30 to +30
	double oscillatorScore = GetOscillatorScore(); // -20 to +20
	double volumeScore = GetVolumeScore();         // -10 to +10
	
	// Combined signal score
	double totalScore = trendScore + momentumScore + oscillatorScore + volumeScore;
	signal.signalStrength = totalScore;
	signal.confidence = MathAbs(totalScore);
	
	// Apply filters
	bool m5TrendAlign = CheckM5TrendAlignment(totalScore);
	bool adxStrong = CheckADXStrength();
	bool volumeConfirm = CheckVolumeConfirmation();
	bool regimeOK = CheckMarketRegime();
	
	// Determine signal direction
	if(totalScore >= 60 && m5TrendAlign && regimeOK) {
		signal.direction = 1; // CALL
		signal.reason = StringFormat("Strong CALL Signal (Score: %.1f)", totalScore);
	}
	else if(totalScore <= -60 && m5TrendAlign && regimeOK) {
		signal.direction = -1; // PUT
		signal.reason = StringFormat("Strong PUT Signal (Score: %.1f)", totalScore);
	}
	else {
		signal.reason = StringFormat("Weak Signal (Score: %.1f)", totalScore);
	}
	
	// High quality signal check
	if(signal.direction != 0) {
		signal.isHighQuality = (signal.confidence >= 70 && 
							   m5TrendAlign && 
							   adxStrong && 
							   (UseVolumeFilter ? volumeConfirm : true));
	}
	
	return signal;
}

//+------------------------------------------------------------------+
//| Get Trend Score from EMA                                         |
//+------------------------------------------------------------------+
double GetTrendScore() {
	double ema_fast[], ema_slow[];
	if(CopyBuffer(ema_fast_handle, 0, 1, 1, ema_fast) <= 0 ||
	   CopyBuffer(ema_slow_handle, 0, 1, 1, ema_slow) <= 0) {
		return 0;
	}
	
	double score = 0;
	
	// EMA Cross Score (±20 points)
	if(ema_fast[0] > ema_slow[0]) score += 20;
	else if(ema_fast[0] < ema_slow[0]) score -= 20;
	
	// EMA Distance Score (±20 points)
	double distance = MathAbs(ema_fast[0] - ema_slow[0]) / Point();
	double normalizedDistance = MathMin(distance / 100, 1.0); // Normalize to 0-1
	
	if(ema_fast[0] > ema_slow[0]) score += normalizedDistance * 20;
	else score -= normalizedDistance * 20;
	
	return score;
}

//+------------------------------------------------------------------+
//| Get Momentum Score from RSI and MACD                             |
//+------------------------------------------------------------------+
double GetMomentumScore() {
	double rsi[], macd_main[], macd_signal[];
	if(CopyBuffer(rsi_handle, 0, 1, 1, rsi) <= 0 ||
	   CopyBuffer(macd_handle, 0, 1, 1, macd_main) <= 0 ||
	   CopyBuffer(macd_handle, 1, 1, 1, macd_signal) <= 0) {
		return 0;
	}
	
	double score = 0;
	
	// RSI Score (±15 points)
	if(rsi[0] > 55 && rsi[0] < 80) score += 15;
	else if(rsi[0] < 45 && rsi[0] > 20) score -= 15;
	else if(rsi[0] >= 80) score -= 5; // Overbought
	else if(rsi[0] <= 20) score += 5; // Oversold
	
	// MACD Score (±15 points)
	if(macd_main[0] > macd_signal[0] && macd_main[0] > 0) score += 15;
	else if(macd_main[0] < macd_signal[0] && macd_main[0] < 0) score -= 15;
	else if(macd_main[0] > macd_signal[0] && macd_main[0] <= 0) score += 8;
	else if(macd_main[0] < macd_signal[0] && macd_main[0] >= 0) score -= 8;
	
	return score;
}

//+------------------------------------------------------------------+
//| Get Oscillator Score from Stochastic and Bollinger Bands        |
//+------------------------------------------------------------------+
double GetOscillatorScore() {
	double stoch_k[], stoch_d[], bb_upper[], bb_middle[], bb_lower[];
	double close = iClose(Symbol(), PERIOD_M1, 1);
	
	if(CopyBuffer(stoch_handle, 0, 1, 1, stoch_k) <= 0 ||
	   CopyBuffer(stoch_handle, 1, 1, 1, stoch_d) <= 0 ||
	   CopyBuffer(bb_handle, 0, 1, 1, bb_upper) <= 0 ||
	   CopyBuffer(bb_handle, 1, 1, 1, bb_middle) <= 0 ||
	   CopyBuffer(bb_handle, 2, 1, 1, bb_lower) <= 0) {
		return 0;
	}
	
	double score = 0;
	
	// Stochastic Score (±10 points)
	if(stoch_k[0] > stoch_d[0] && stoch_k[0] > 50) score += 10;
	else if(stoch_k[0] < stoch_d[0] && stoch_k[0] < 50) score -= 10;
	
	// Bollinger Bands Score (±10 points)
	if(close > bb_middle[0]) score += 10;
	else if(close < bb_middle[0]) score -= 10;
	
	// Bollinger Bands extreme positions
	if(close > bb_upper[0]) score -= 5; // Overbought
	else if(close < bb_lower[0]) score += 5; // Oversold
	
	return score;
}

//+------------------------------------------------------------------+
//| Get Volume Score                                                 |
//+------------------------------------------------------------------+
double GetVolumeScore() {
	if(!UseVolumeFilter) return 0;
	
	double volume = (double)iVolume(Symbol(), PERIOD_M1, 1);
	double volume_ma[];
	if(CopyBuffer(volume_ma_handle, 0, 1, 1, volume_ma) <= 0) {
		return 0;
	}
	
	double score = 0;
	
	// Volume confirmation (±10 points)
	if(volume > volume_ma[0] * 1.2) score += 10;
	else if(volume < volume_ma[0] * 0.8) score -= 5;
	
	return score;
}

//+------------------------------------------------------------------+
//| Check M5 Trend Alignment                                         |
//+------------------------------------------------------------------+
bool CheckM5TrendAlignment(double m1Signal) {
	if(!UseMultiTimeframe) return true;
	
	double ema_fast_m5[], ema_slow_m5[];
	if(CopyBuffer(ema_fast_m5_handle, 0, 0, 1, ema_fast_m5) <= 0 ||
	   CopyBuffer(ema_slow_m5_handle, 0, 0, 1, ema_slow_m5) <= 0) {
		return false;
	}
	
	bool m5_bullish = (ema_fast_m5[0] > ema_slow_m5[0]);
	bool m5_bearish = (ema_fast_m5[0] < ema_slow_m5[0]);
	
	if(m1Signal > 0 && m5_bullish) return true;
	if(m1Signal < 0 && m5_bearish) return true;
	
	return false;
}

//+------------------------------------------------------------------+
//| Check ADX Strength                                               |
//+------------------------------------------------------------------+
bool CheckADXStrength() {
	double adx[];
	if(CopyBuffer(adx_handle, 0, 1, 1, adx) <= 0) {
		return false;
	}
	
	return (adx[0] > 25);
}

//+------------------------------------------------------------------+
//| Check Volume Confirmation                                        |
//+------------------------------------------------------------------+
bool CheckVolumeConfirmation() {
	if(!UseVolumeFilter) return true;
	
	double volume = (double)iVolume(Symbol(), PERIOD_M1, 1);
	double volume_ma[];
	if(CopyBuffer(volume_ma_handle, 0, 1, 1, volume_ma) <= 0) {
		return false;
	}
	
	return (volume > volume_ma[0] * 1.1);
}

//+------------------------------------------------------------------+
//| Check Market Regime                                              |
//+------------------------------------------------------------------+
bool CheckMarketRegime() {
	if(!UseMarketRegimeFilter) return true;
	
	MarketRegime regime = DetectMarketRegime();
	
	// Avoid trading in highly volatile or completely flat markets
	return (regime == TRENDING_UP || regime == TRENDING_DOWN || regime == SIDEWAYS);
}

//+------------------------------------------------------------------+
//| Detect Market Regime                                             |
//+------------------------------------------------------------------+
MarketRegime DetectMarketRegime() {
	double atr[], atr_ma[];
	double ema_fast_h1[], ema_slow_h1[];
	
	int atr_h1 = iATR(Symbol(), PERIOD_H1, 14);
	int atr_ma_h1 = iMA(Symbol(), PERIOD_H1, 20, 0, MODE_SMA, atr_h1);
	int ema_fast_h1 = iMA(Symbol(), PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);
	int ema_slow_h1 = iMA(Symbol(), PERIOD_H1, 55, 0, MODE_EMA, PRICE_CLOSE);
	
	if(CopyBuffer(atr_h1, 0, 0, 1, atr) <= 0 ||
	   CopyBuffer(atr_ma_h1, 0, 0, 1, atr_ma) <= 0 ||
	   CopyBuffer(ema_fast_h1, 0, 0, 1, ema_fast_h1) <= 0 ||
	   CopyBuffer(ema_slow_h1, 0, 0, 1, ema_slow_h1) <= 0) {
		return SIDEWAYS;
	}
	
	// High volatility check
	if(atr[0] > atr_ma[0] * 1.5) return VOLATILE;
	
	// Trend detection
	double trendStrength = MathAbs(ema_fast_h1[0] - ema_slow_h1[0]) / Point();
	if(trendStrength > 200) {
		return (ema_fast_h1[0] > ema_slow_h1[0]) ? TRENDING_UP : TRENDING_DOWN;
	}
	
	return SIDEWAYS;
}

//+------------------------------------------------------------------+
//| Validate Signal Quality                                          |
//+------------------------------------------------------------------+
bool ValidateSignal(BinarySignal &signal) {
	// Basic validation
	if(signal.direction == 0) return false;
	if(signal.confidence < MinSignalConfidence) return false;
	
	// High quality requirement
	if(UseMultiTimeframe && !signal.isHighQuality) return false;
	
	// Consecutive losses check
	if(g_stats.consecutiveLosses >= MaxMartingaleSteps) return false;
	
	return true;
}

//+------------------------------------------------------------------+
//| Calculate Trade Amount with Risk Management                      |
//+------------------------------------------------------------------+
double CalculateTradeAmount() {
	double balance = AccountInfoDouble(ACCOUNT_BALANCE);
	
	// Base amount calculation
	double baseAmount = MathMin(BaseAmount, balance * MaxRiskPercent);
	
	// Adaptive Martingale based on current step
	double multiplier = 1.0;
	double winRate = GetWinRate();
	
	if(g_stats.currentStep > 1) {
		if(winRate >= 0.65) {
			// High win rate: Conservative martingale
			double multipliers[] = {1.0, 1.5, 2.2, 3.3, 5.0};
			multiplier = multipliers[MathMin(g_stats.currentStep - 1, 4)];
		}
		else if(winRate >= 0.60) {
			// Medium win rate: Standard martingale
			double multipliers[] = {1.0, 2.0, 4.5, 10.0, 22.5};
			multiplier = multipliers[MathMin(g_stats.currentStep - 1, 4)];
		}
		// Low win rate: No martingale (multiplier = 1.0)
	}
	
	double amount = baseAmount * multiplier;
	
	// Cap at maximum risk (10% of balance)
	double maxAmount = balance * 0.10;
	amount = MathMin(amount, maxAmount);
	
	return NormalizeDouble(amount, 2);
}

//+------------------------------------------------------------------+
//| Send Binary Option Signal via MT2Trading                         |
//+------------------------------------------------------------------+
bool SendBinarySignal(BinarySignal &signal, double amount) {
	if(signal.direction == 0 || amount <= 0) return false;
	
	string direction = (signal.direction == 1) ? "CALL" : "PUT";
	string signalID = SignalPrefix + "_" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
	
	bool result = mt2trading(
		g_asset,                    // Symbol
		direction,                  // CALL or PUT
		amount,                     // Trade amount
		1,                          // 1 minute expiry
		MartingaleType,             // Martingale type
		1,                          // Single step (handled internally)
		1.0,                        // No multiplier
		TargetBroker,               // Target broker
		SignalName,                 // Signal name
		signalID                    // Signal ID
	);
	
	if(result) {
		Print("✅ Signal Sent: ", direction, " | Amount: $", amount, " | Confidence: ", 
			  DoubleToString(signal.confidence, 1), "% | ID: ", signalID);
	}
	else {
		Print("❌ Failed to send signal: ", direction);
	}
	
	return result;
}

//+------------------------------------------------------------------+
//| Record Trade Statistics                                          |
//+------------------------------------------------------------------+
void RecordTrade(BinarySignal &signal, double amount) {
	g_stats.totalTrades++;
	g_stats.lastTradeTime = TimeCurrent();
	
	// Store for result checking (simplified - in real implementation,
	// you would track individual trades and their results)
	Print("📊 Trade Recorded: ", 
		  "Signal: ", (signal.direction == 1 ? "CALL" : "PUT"),
		  " | Amount: $", amount,
		  " | Step: ", g_stats.currentStep,
		  " | Total Trades: ", g_stats.totalTrades);
}

//+------------------------------------------------------------------+
//| Check if current time is valid for trading                       |
//+------------------------------------------------------------------+
bool IsValidTradingTime() {
	MqlDateTime dt;
	TimeToStruct(TimeGMT(), dt);
	int hour = dt.hour;
	
	// Basic hour check
	if(hour < StartHour || hour >= EndHour) return false;
	
	// Session-specific checks
	bool londonTime = (hour >= 8 && hour < 17);   // London: 8-17 GMT
	bool newYorkTime = (hour >= 13 && hour < 22); // New York: 13-22 GMT
	bool overlapTime = (hour >= 13 && hour < 17); // Overlap: 13-17 GMT
	
	if(TradeLondonSession && londonTime) return true;
	if(TradeNewYorkSession && newYorkTime) return true;
	if(overlapTime) return true; // Best time
	
	return false;
}

//+------------------------------------------------------------------+
//| Check if it's news time (simplified implementation)              |
//+------------------------------------------------------------------+
bool IsNewsTime() {
	if(!AvoidNews) return false;
	
	MqlDateTime dt;
	TimeToStruct(TimeGMT(), dt);
	
	// Avoid major news times (simplified)
	// US news typically at 12:30, 14:00, 15:00 GMT
	// EU news typically at 08:30, 09:00, 10:00 GMT
	int newsHours[] = {8, 9, 10, 12, 14, 15};
	int newsMinutes[] = {0, 30};
	
	for(int i = 0; i < ArraySize(newsHours); i++) {
		if(dt.hour == newsHours[i]) {
			for(int j = 0; j < ArraySize(newsMinutes); j++) {
				if(MathAbs(dt.min - newsMinutes[j]) <= 15) { // 15 minutes before/after
					return true;
				}
			}
		}
	}
	
	return false;
}

//+------------------------------------------------------------------+
//| Check Daily Limits                                               |
//+------------------------------------------------------------------+
bool CheckDailyLimits() {
	// Update daily P&L (simplified)
	double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
	
	// Check daily loss limit
	if(g_limits.dailyLossLimitReached) {
		return false;
	}
	
	// Check daily profit target
	if(g_limits.dailyTargetReached) {
		return false;
	}
	
	// Check max daily trades
	if(g_stats.totalTrades >= 50) {
		Print("⚠️ Maximum daily trades reached (50)");
		return false;
	}
	
	// Check consecutive losses
	if(g_stats.consecutiveLosses >= MaxMartingaleSteps) {
		Print("⚠️ Maximum consecutive losses reached (", MaxMartingaleSteps, ")");
		return false;
	}
	
	return true;
}

//+------------------------------------------------------------------+
//| Get Current Win Rate                                             |
//+------------------------------------------------------------------+
double GetWinRate() {
	if(g_stats.totalTrades == 0) return 0.60; // Default assumption
	
	return (double)g_stats.winTrades / g_stats.totalTrades;
}

//+------------------------------------------------------------------+
//| Initialize Statistics                                            |
//+------------------------------------------------------------------+
void InitializeStats() {
	ZeroMemory(g_stats);
	g_stats.currentStep = 1;
	g_stats.dayStartTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Initialize Daily Limits                                          |
//+------------------------------------------------------------------+
void InitializeDailyLimits() {
	double balance = AccountInfoDouble(ACCOUNT_BALANCE);
	
	g_limits.maxDailyLoss = balance * DailyLossLimit;
	g_limits.maxDailyProfit = balance * DailyProfitTarget;
	g_limits.maxDailyTrades = 50;
	g_limits.maxConsecutiveLosses = MaxMartingaleSteps;
	g_limits.dailyTargetReached = false;
	g_limits.dailyLossLimitReached = false;
}

//+------------------------------------------------------------------+
//| Reset Daily Counters                                            |
//+------------------------------------------------------------------+
void ResetDailyCounters() {
	PrintDailyReport();
	
	g_stats.totalTrades = 0;
	g_stats.dailyPnL = 0;
	g_stats.dayStartTime = TimeCurrent();
	
	InitializeDailyLimits();
	
	Print("📅 Daily counters reset for new trading day");
}

//+------------------------------------------------------------------+
//| Print Trade Information                                          |
//+------------------------------------------------------------------+
void PrintTradeInfo(BinarySignal &signal, double amount) {
	Print("🎯 === TRADE EXECUTED ===");
	Print("Direction: ", (signal.direction == 1 ? "📈 CALL" : "📉 PUT"));
	Print("Amount: $", DoubleToString(amount, 2));
	Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
	Print("Step: ", g_stats.currentStep);
	Print("Reason: ", signal.reason);
	Print("Win Rate: ", DoubleToString(GetWinRate() * 100, 1), "%");
	Print("Total Trades Today: ", g_stats.totalTrades);
	Print("========================");
}

//+------------------------------------------------------------------+
//| Print Hourly Statistics                                          |
//+------------------------------------------------------------------+
void PrintHourlyStats() {
	double winRate = GetWinRate() * 100;
	
	Print("⏰ === HOURLY REPORT ===");
	Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
	Print("Trades Today: ", g_stats.totalTrades);
	Print("Win Rate: ", DoubleToString(winRate, 1), "%");
	Print("Current Step: ", g_stats.currentStep);
	Print("Consecutive Losses: ", g_stats.consecutiveLosses);
	Print("Account Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
	Print("======================");
}

//+------------------------------------------------------------------+
//| Print Daily Report                                               |
//+------------------------------------------------------------------+
void PrintDailyReport() {
	double winRate = GetWinRate() * 100;
	
	Print("📊 === DAILY REPORT ===");
	Print("Date: ", TimeToString(TimeCurrent(), TIME_DATE));
	Print("Total Trades: ", g_stats.totalTrades);
	Print("Win Trades: ", g_stats.winTrades);
	Print("Loss Trades: ", g_stats.lossTrades);
	Print("Win Rate: ", DoubleToString(winRate, 1), "%");
	Print("Daily P&L: $", DoubleToString(g_stats.dailyPnL, 2));
	Print("Account Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
	Print("======================");
}

//+------------------------------------------------------------------+
//| Print Final Statistics                                           |
//+------------------------------------------------------------------+
void PrintFinalStats() {
	Print("🏁 === FINAL STATISTICS ===");
	PrintDailyReport();
	Print("EA Runtime: ", DoubleToString((TimeCurrent() - g_stats.dayStartTime) / 3600.0, 1), " hours");
	Print("===========================");
}

//+------------------------------------------------------------------+
//| Emergency Stop Check                                             |
//+------------------------------------------------------------------+
void CheckEmergencyStop() {
	double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
	double startBalance = currentBalance + g_stats.dailyPnL; // Approximate
	
	if(startBalance > 0) {
		double drawdown = (startBalance - currentBalance) / startBalance * 100;
		
		if(drawdown >= 20.0) {
			Print("🚨 EMERGENCY STOP: Drawdown exceeded 20%");
			Print("Starting Balance: $", DoubleToString(startBalance, 2));
			Print("Current Balance: $", DoubleToString(currentBalance, 2));
			Print("Drawdown: ", DoubleToString(drawdown, 2), "%");
			
			ExpertRemove();
		}
		else if(drawdown >= 15.0) {
			Print("⚠️ WARNING: Drawdown approaching 15%");
		}
	}
} 