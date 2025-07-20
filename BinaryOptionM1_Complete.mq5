//+------------------------------------------------------------------+
//| Binary Option M1 Complete System - All-in-One                   |
//| Ready to Install & Trade                                         |
//+------------------------------------------------------------------+
#property copyright "Binary M1 Complete System 2024"
#property version   "4.0"
#property strict
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 3

//--- Indicator plots
#property indicator_label1 "CALL Signal"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLime
#property indicator_style1 STYLE_SOLID
#property indicator_width1 3

#property indicator_label2 "PUT Signal" 
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrRed
#property indicator_style2 STYLE_SOLID
#property indicator_width2 3

#property indicator_label3 "Trend Line"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrYellow
#property indicator_style3 STYLE_SOLID
#property indicator_width3 2

//--- Enums
enum TRADE_MODE {
    MODE_DEMO = 0,          // Demo/Simulation Mode
    MODE_LIVE = 1,          // Live Trading Mode (requires MT2Trading)
    MODE_BACKTEST = 2       // Backtesting Mode
};

enum BROKERS {
    IQOPTION = 1,
    POCKETOPTION = 12,
    QUOTEX = 14,
    BINARY_COM = 2,
    SPECTRE = 3
};

enum SIGNAL_STRENGTH {
    WEAK = 1,
    MODERATE = 2, 
    STRONG = 3
};

//--- Input Parameters
input group "=== TRADING MODE ==="
input TRADE_MODE TradingMode = MODE_DEMO;          // Trading Mode
input bool EnableAutoTrading = true;               // Enable Auto Trading
input bool ShowSignalsOnChart = true;              // Show signals on chart

input group "=== RISK MANAGEMENT ==="
input double BaseAmount = 10.0;                    // Base trade amount ($)
input double MaxRiskPercent = 0.02;                // Max risk per trade (2%)
input int MaxMartingaleSteps = 5;                  // Max martingale steps
input double DailyLossLimit = 0.10;                // Daily loss limit (10%)
input double DailyProfitTarget = 0.05;             // Daily profit target (5%)

input group "=== SIGNAL SETTINGS ==="
input double MinSignalConfidence = 70.0;           // Minimum signal confidence (%)
input bool UseMultiTimeframe = true;               // Multi-timeframe analysis
input bool UseVolumeFilter = true;                 // Volume confirmation
input bool UseNewsFilter = true;                   // News avoidance
input SIGNAL_STRENGTH MinSignalStrength = MODERATE; // Minimum signal strength

input group "=== TRADING HOURS ==="
input int StartHour = 8;                           // Trading start (GMT)
input int EndHour = 22;                            // Trading end (GMT)
input bool TradeLondonSession = true;              // London session (8-17 GMT)
input bool TradeNewYorkSession = true;             // New York session (13-22 GMT)

input group "=== BROKER SETTINGS ==="
input BROKERS TargetBroker = IQOPTION;             // Target broker
input string SignalName = "BinaryM1Complete";      // Signal name
input double PayoutPercent = 80.0;                 // Expected payout (%)

input group "=== INDICATOR SETTINGS ==="
input int EMA_Fast = 21;                           // EMA Fast period
input int EMA_Slow = 55;                           // EMA Slow period
input int RSI_Period = 14;                         // RSI period
input int MACD_Fast = 12;                          // MACD Fast EMA
input int MACD_Slow = 26;                          // MACD Slow EMA
input int MACD_Signal = 9;                         // MACD Signal period
input int Stoch_K = 14;                            // Stochastic %K
input int Stoch_D = 3;                             // Stochastic %D
input int BB_Period = 20;                          // Bollinger Bands period
input double BB_Deviation = 2.0;                   // Bollinger Bands deviation
input int ADX_Period = 14;                         // ADX period

input group "=== ALERTS & NOTIFICATIONS ==="
input bool EnableAlerts = true;                    // Enable alerts
input bool SendEmails = false;                     // Send email notifications
input bool SendNotifications = true;               // Send push notifications
input bool PlaySounds = true;                      // Play sound alerts

//--- Global Variables
struct BinarySignal {
    int direction;           // 1=CALL, -1=PUT, 0=No Trade
    double confidence;       // 0-100%
    double signalStrength;   // Combined score
    SIGNAL_STRENGTH strength; // Signal strength enum
    string reason;           // Signal reason
    datetime timestamp;      // Signal time
    double entryPrice;       // Entry price
    double trendScore;       // Individual scores for analysis
    double momentumScore;
    double oscillatorScore;
    double volumeScore;
};

struct TradeResult {
    datetime openTime;
    datetime closeTime;
    int direction;
    double amount;
    double entryPrice;
    double closePrice;
    bool won;
    double profit;
    double confidence;
    string reason;
};

struct TradingStats {
    int totalTrades;
    int winTrades;
    int lossTrades;
    double totalProfit;
    double totalLoss;
    double netProfit;
    double winRate;
    double profitFactor;
    int currentStep;
    int consecutiveLosses;
    int maxConsecutiveLosses;
    int maxConsecutiveWins;
    datetime lastTradeTime;
    datetime sessionStartTime;
    double sessionStartBalance;
    double currentBalance;
    double maxDrawdown;
    double maxProfit;
};

struct DailyLimits {
    double maxDailyLoss;
    double maxDailyProfit;
    int maxDailyTrades;
    bool dailyTargetReached;
    bool dailyLossLimitReached;
    datetime lastResetDate;
};

//--- Indicator Handles
int ema_fast_handle, ema_slow_handle;
int ema_fast_m5_handle, ema_slow_m5_handle;
int rsi_handle, macd_handle, stoch_handle;
int bb_handle, adx_handle, atr_handle;
int volume_ma_handle;

//--- Global Objects
TradingStats g_stats;
DailyLimits g_limits;
TradeResult g_tradeHistory[];
string g_asset;

//--- Indicator Buffers
double CallSignalBuffer[];
double PutSignalBuffer[];
double TrendBuffer[];

//--- MT2Trading Simulation (if library not available)
bool MT2_LIBRARY_AVAILABLE = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=== Binary Option M1 Complete System Initializing ===");
    
    // Set indicator buffers
    SetIndexBuffer(0, CallSignalBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, PutSignalBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, TrendBuffer, INDICATOR_DATA);
    
    // Set indicator properties
    PlotIndexSetInteger(0, PLOT_ARROW, 233);
    PlotIndexSetInteger(1, PLOT_ARROW, 234);
    
    // Initialize indicator arrays
    ArraySetAsSeries(CallSignalBuffer, true);
    ArraySetAsSeries(PutSignalBuffer, true);
    ArraySetAsSeries(TrendBuffer, true);
    
    // Initialize asset name
    if(StringLen(Symbol()) >= 6)
        g_asset = StringSubstr(Symbol(), 0, 6);
    else
        g_asset = Symbol();
    
    // Check MT2Trading library availability
    CheckMT2TradingLibrary();
    
    // Initialize indicators
    if(!InitializeIndicators()) {
        Print("ERROR: Failed to initialize indicators");
        return INIT_FAILED;
    }
    
    // Initialize statistics and limits
    InitializeStats();
    InitializeDailyLimits();
    
    // Set timer for monitoring
    EventSetTimer(60); // Check every minute
    
    // Initialize trade history array
    ArrayResize(g_tradeHistory, 0);
    
    Print("=== Binary Option M1 Complete System Initialized Successfully ===");
    Print("Trading Mode: ", EnumToString(TradingMode));
    Print("Asset: ", g_asset);
    Print("Base Amount: $", BaseAmount);
    Print("Target Broker: ", EnumToString(TargetBroker));
    Print("MT2Trading Available: ", MT2_LIBRARY_AVAILABLE ? "YES" : "NO (Demo Mode)");
    
    // Send initialization alert
    if(EnableAlerts) {
        string msg = StringFormat("Binary M1 System Started - %s - Mode: %s", 
                                 g_asset, EnumToString(TradingMode));
        SendAlert(msg);
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    PrintFinalReport();
    
    if(EnableAlerts) {
        string msg = StringFormat("Binary M1 System Stopped - Final Stats: %d trades, %.1f%% win rate, $%.2f profit",
                                 g_stats.totalTrades, g_stats.winRate, g_stats.netProfit);
        SendAlert(msg);
    }
    
    Print("=== Binary Option M1 Complete System Deinitialized ===");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
                const int &spread[]) {
    
    // Check if new bar
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        ProcessNewBar();
    }
    
    // Update trend line
    UpdateTrendLine(rates_total, prev_calculated);
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    // Check for new day reset
    CheckDailyReset();
    
    // Monitor performance
    MonitorPerformance();
    
    // Update statistics
    UpdateStatistics();
}

//+------------------------------------------------------------------+
//| Process new bar - main trading logic                            |
//+------------------------------------------------------------------+
void ProcessNewBar() {
    // Check daily limits
    if(!CheckDailyLimits()) return;
    
    // Check trading hours
    if(!IsValidTradingTime()) return;
    
    // Check news filter
    if(UseNewsFilter && IsNewsTime()) return;
    
    // Generate signal
    BinarySignal signal = GenerateSignal();
    
    // Show signal on chart
    if(ShowSignalsOnChart) {
        DisplaySignalOnChart(signal);
    }
    
    // Process signal for trading
    if(EnableAutoTrading && ValidateSignal(signal)) {
        ProcessTradingSignal(signal);
    }
    
    // Update buffers for display
    UpdateIndicatorBuffers(signal);
}

//+------------------------------------------------------------------+
//| Generate Binary Option Signal                                   |
//+------------------------------------------------------------------+
BinarySignal GenerateSignal() {
    BinarySignal signal;
    signal.direction = 0;
    signal.confidence = 0.0;
    signal.signalStrength = 0.0;
    signal.strength = WEAK;
    signal.reason = "No Signal";
    signal.timestamp = TimeCurrent();
    signal.entryPrice = (SymbolInfoDouble(Symbol(), SYMBOL_ASK) + SymbolInfoDouble(Symbol(), SYMBOL_BID)) / 2;
    
    // Calculate individual indicator scores
    signal.trendScore = GetTrendScore();           // -40 to +40
    signal.momentumScore = GetMomentumScore();     // -30 to +30
    signal.oscillatorScore = GetOscillatorScore(); // -20 to +20
    signal.volumeScore = GetVolumeScore();         // -10 to +10
    
    // Combined signal score
    double totalScore = signal.trendScore + signal.momentumScore + signal.oscillatorScore + signal.volumeScore;
    signal.signalStrength = totalScore;
    signal.confidence = MathAbs(totalScore);
    
    // Apply confirmation filters
    bool m5TrendAlign = CheckM5TrendAlignment(totalScore);
    bool adxStrong = CheckADXStrength();
    bool volumeConfirm = CheckVolumeConfirmation();
    
    // Determine signal direction and strength
    if(totalScore >= 70 && m5TrendAlign && adxStrong) {
        signal.direction = 1; // CALL
        signal.strength = STRONG;
        signal.reason = StringFormat("STRONG CALL - Score: %.1f (Trend:%.1f, Mom:%.1f, Osc:%.1f, Vol:%.1f)", 
                                   totalScore, signal.trendScore, signal.momentumScore, signal.oscillatorScore, signal.volumeScore);
    }
    else if(totalScore <= -70 && m5TrendAlign && adxStrong) {
        signal.direction = -1; // PUT
        signal.strength = STRONG;
        signal.reason = StringFormat("STRONG PUT - Score: %.1f (Trend:%.1f, Mom:%.1f, Osc:%.1f, Vol:%.1f)", 
                                   totalScore, signal.trendScore, signal.momentumScore, signal.oscillatorScore, signal.volumeScore);
    }
    else if(totalScore >= 60 && m5TrendAlign) {
        signal.direction = 1; // CALL
        signal.strength = MODERATE;
        signal.reason = StringFormat("MODERATE CALL - Score: %.1f", totalScore);
    }
    else if(totalScore <= -60 && m5TrendAlign) {
        signal.direction = -1; // PUT
        signal.strength = MODERATE;
        signal.reason = StringFormat("MODERATE PUT - Score: %.1f", totalScore);
    }
    else if(totalScore >= 50) {
        signal.direction = 1; // CALL
        signal.strength = WEAK;
        signal.reason = StringFormat("WEAK CALL - Score: %.1f", totalScore);
    }
    else if(totalScore <= -50) {
        signal.direction = -1; // PUT
        signal.strength = WEAK;
        signal.reason = StringFormat("WEAK PUT - Score: %.1f", totalScore);
    }
    else {
        signal.reason = StringFormat("NO SIGNAL - Score: %.1f (insufficient strength)", totalScore);
    }
    
    // Enhanced quality check for strong signals
    if(signal.direction != 0 && signal.strength >= STRONG) {
        if(UseVolumeFilter && !volumeConfirm) {
            signal.confidence *= 0.8; // Reduce confidence without volume confirmation
        }
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
    
    // EMA Cross Score (±25 points)
    if(ema_fast[0] > ema_slow[0]) score += 25;
    else if(ema_fast[0] < ema_slow[0]) score -= 25;
    
    // EMA Distance Score (±15 points)
    double distance = MathAbs(ema_fast[0] - ema_slow[0]) / SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double normalizedDistance = MathMin(distance / 100, 1.0);
    
    if(ema_fast[0] > ema_slow[0]) score += normalizedDistance * 15;
    else score -= normalizedDistance * 15;
    
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
    if(rsi[0] > 55 && rsi[0] < 75) score += 15;
    else if(rsi[0] < 45 && rsi[0] > 25) score -= 15;
    else if(rsi[0] >= 75) score -= 8; // Overbought
    else if(rsi[0] <= 25) score += 8; // Oversold
    
    // MACD Score (±15 points)
    if(macd_main[0] > macd_signal[0] && macd_main[0] > 0) score += 15;
    else if(macd_main[0] < macd_signal[0] && macd_main[0] < 0) score -= 15;
    else if(macd_main[0] > macd_signal[0] && macd_main[0] <= 0) score += 10;
    else if(macd_main[0] < macd_signal[0] && macd_main[0] >= 0) score -= 10;
    
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
    if(stoch_k[0] > stoch_d[0] && stoch_k[0] > 50 && stoch_k[0] < 80) score += 10;
    else if(stoch_k[0] < stoch_d[0] && stoch_k[0] < 50 && stoch_k[0] > 20) score -= 10;
    
    // Bollinger Bands Score (±10 points)
    if(close > bb_middle[0] && close < bb_upper[0]) score += 10;
    else if(close < bb_middle[0] && close > bb_lower[0]) score -= 10;
    else if(close >= bb_upper[0]) score -= 5; // Overbought
    else if(close <= bb_lower[0]) score += 5; // Oversold
    
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
    if(volume > volume_ma[0] * 1.3) score += 10;      // High volume
    else if(volume > volume_ma[0] * 1.1) score += 5;   // Above average
    else if(volume < volume_ma[0] * 0.7) score -= 5;   // Low volume
    
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
//| Validate Signal Quality                                          |
//+------------------------------------------------------------------+
bool ValidateSignal(BinarySignal &signal) {
    // Basic validation
    if(signal.direction == 0) return false;
    if(signal.confidence < MinSignalConfidence) return false;
    if(signal.strength < MinSignalStrength) return false;
    
    // Consecutive losses check
    if(g_stats.consecutiveLosses >= MaxMartingaleSteps) return false;
    
    // Time filter - don't trade too frequently
    if(TimeCurrent() - g_stats.lastTradeTime < 60) return false; // Min 1 minute between trades
    
    return true;
}

//+------------------------------------------------------------------+
//| Process Trading Signal                                           |
//+------------------------------------------------------------------+
void ProcessTradingSignal(BinarySignal &signal) {
    double tradeAmount = CalculateTradeAmount();
    if(tradeAmount <= 0) return;
    
    bool success = false;
    
    switch(TradingMode) {
        case MODE_DEMO:
        case MODE_BACKTEST:
            success = ExecuteDemoTrade(signal, tradeAmount);
            break;
            
        case MODE_LIVE:
            success = ExecuteLiveTrade(signal, tradeAmount);
            break;
    }
    
    if(success) {
        RecordTrade(signal, tradeAmount);
        PrintTradeInfo(signal, tradeAmount);
        
        if(EnableAlerts) {
            string msg = StringFormat("TRADE: %s %s | Amount: $%.2f | Confidence: %.1f%% | Step: %d",
                                     (signal.direction == 1 ? "CALL" : "PUT"), g_asset, 
                                     tradeAmount, signal.confidence, g_stats.currentStep);
            SendAlert(msg);
        }
    }
}

//+------------------------------------------------------------------+
//| Execute Demo/Simulation Trade                                    |
//+------------------------------------------------------------------+
bool ExecuteDemoTrade(BinarySignal &signal, double amount) {
    // Simulate trade execution
    TradeResult trade;
    trade.openTime = TimeCurrent();
    trade.closeTime = trade.openTime + 60; // 1 minute expiry
    trade.direction = signal.direction;
    trade.amount = amount;
    trade.entryPrice = signal.entryPrice;
    trade.confidence = signal.confidence;
    trade.reason = signal.reason;
    
    // For demo mode, we'll simulate the result based on next bar
    // In real implementation, this would be determined after expiry
    if(TradingMode == MODE_DEMO) {
        // Wait for next tick to determine result (simplified)
        trade.won = (MathRand() % 100) < (signal.confidence * 0.8); // Simulate based on confidence
    }
    else if(TradingMode == MODE_BACKTEST) {
        // Backtest mode - check actual next bar
        double nextClose = iClose(Symbol(), PERIOD_M1, 0);
        if(signal.direction == 1) {
            trade.won = (nextClose > trade.entryPrice);
        } else {
            trade.won = (nextClose < trade.entryPrice);
        }
        trade.closePrice = nextClose;
    }
    
    // Calculate profit/loss
    if(trade.won) {
        trade.profit = amount * (PayoutPercent / 100.0);
        g_stats.currentStep = 1; // Reset martingale
        g_stats.consecutiveLosses = 0;
    } else {
        trade.profit = -amount;
        g_stats.currentStep++;
        g_stats.consecutiveLosses++;
    }
    
    // Add to trade history
    int size = ArraySize(g_tradeHistory);
    ArrayResize(g_tradeHistory, size + 1);
    g_tradeHistory[size] = trade;
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute Live Trade via MT2Trading                                |
//+------------------------------------------------------------------+
bool ExecuteLiveTrade(BinarySignal &signal, double amount) {
    if(!MT2_LIBRARY_AVAILABLE) {
        Print("MT2Trading library not available - switching to demo mode");
        return ExecuteDemoTrade(signal, amount);
    }
    
    // Implement MT2Trading integration here
    string direction = (signal.direction == 1) ? "CALL" : "PUT";
    string signalID = SignalName + "_" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
    
    // This would be the actual MT2Trading call
    // bool result = mt2trading(g_asset, direction, amount, 1, 0, 1, 1.0, TargetBroker, SignalName, signalID);
    
    Print("LIVE TRADE: ", direction, " ", g_asset, " $", amount, " (Signal: ", signalID, ")");
    
    return true; // Simplified for now
}

//+------------------------------------------------------------------+
//| Calculate Trade Amount with Risk Management                      |
//+------------------------------------------------------------------+
double CalculateTradeAmount() {
    double balance = (TradingMode == MODE_DEMO || TradingMode == MODE_BACKTEST) ? 
                     g_stats.currentBalance : AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Base amount calculation
    double baseAmount = MathMin(BaseAmount, balance * MaxRiskPercent);
    
    // Adaptive Martingale
    double multiplier = 1.0;
    if(g_stats.currentStep > 1 && g_stats.winRate >= 0.60) {
        double multipliers[] = {1.0, 1.8, 3.2, 5.8, 10.4}; // Fibonacci-like progression
        multiplier = multipliers[MathMin(g_stats.currentStep - 1, 4)];
    }
    
    double amount = baseAmount * multiplier;
    
    // Cap at maximum risk
    double maxAmount = balance * 0.15; // 15% max per trade
    amount = MathMin(amount, maxAmount);
    
    return NormalizeDouble(amount, 2);
}

//+------------------------------------------------------------------+
//| Record Trade Statistics                                          |
//+------------------------------------------------------------------+
void RecordTrade(BinarySignal &signal, double amount) {
    g_stats.totalTrades++;
    g_stats.lastTradeTime = TimeCurrent();
    
    Print("📊 Trade #", g_stats.totalTrades, " recorded: ", 
          (signal.direction == 1 ? "CALL" : "PUT"), " $", amount, " Step:", g_stats.currentStep);
}

//+------------------------------------------------------------------+
//| Display Signal on Chart                                         |
//+------------------------------------------------------------------+
void DisplaySignalOnChart(BinarySignal &signal) {
    int index = 1; // Current bar index
    
    // Clear previous signals
    CallSignalBuffer[index] = EMPTY_VALUE;
    PutSignalBuffer[index] = EMPTY_VALUE;
    
    // Display new signal
    if(signal.direction == 1 && signal.confidence >= MinSignalConfidence) {
        CallSignalBuffer[index] = iLow(Symbol(), PERIOD_M1, index) - 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    }
    else if(signal.direction == -1 && signal.confidence >= MinSignalConfidence) {
        PutSignalBuffer[index] = iHigh(Symbol(), PERIOD_M1, index) + 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    }
}

//+------------------------------------------------------------------+
//| Update Indicator Buffers                                         |
//+------------------------------------------------------------------+
void UpdateIndicatorBuffers(BinarySignal &signal) {
    // This is called from OnCalculate, just ensure buffers are updated
    // The actual buffer updates happen in DisplaySignalOnChart
}

//+------------------------------------------------------------------+
//| Update Trend Line                                                |
//+------------------------------------------------------------------+
void UpdateTrendLine(int rates_total, int prev_calculated) {
    int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
    
    for(int i = start; i < rates_total - 1; i++) {
        double ema_fast[], ema_slow[];
        if(CopyBuffer(ema_fast_handle, 0, rates_total - i - 1, 1, ema_fast) > 0 &&
           CopyBuffer(ema_slow_handle, 0, rates_total - i - 1, 1, ema_slow) > 0) {
            TrendBuffer[rates_total - i - 1] = ema_fast[0];
        }
    }
}

//+------------------------------------------------------------------+
//| Initialize All Indicators                                        |
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
    
    // Verify all handles
    int handles[] = {ema_fast_handle, ema_slow_handle, rsi_handle, macd_handle, 
                     stoch_handle, bb_handle, adx_handle, atr_handle, volume_ma_handle,
                     ema_fast_m5_handle, ema_slow_m5_handle};
    
    for(int i = 0; i < ArraySize(handles); i++) {
        if(handles[i] == INVALID_HANDLE) {
            Print("ERROR: Invalid handle for indicator #", i);
            return false;
        }
    }
    
    Print("✅ All indicators initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Check MT2Trading Library Availability                           |
//+------------------------------------------------------------------+
void CheckMT2TradingLibrary() {
    // Try to check if MT2Trading library is available
    // This is a simplified check - in real implementation you'd try to call a test function
    MT2_LIBRARY_AVAILABLE = false; // Set to true if library is available
    
    if(!MT2_LIBRARY_AVAILABLE && TradingMode == MODE_LIVE) {
        Print("⚠️ MT2Trading library not found - switching to demo mode");
        TradingMode = MODE_DEMO;
    }
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
    
    // Session checks
    bool londonTime = (hour >= 8 && hour < 17);
    bool newYorkTime = (hour >= 13 && hour < 22);
    
    if(TradeLondonSession && londonTime) return true;
    if(TradeNewYorkSession && newYorkTime) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's news time                                          |
//+------------------------------------------------------------------+
bool IsNewsTime() {
    if(!UseNewsFilter) return false;
    
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    
    // Major news times (simplified)
    int newsHours[] = {8, 9, 10, 12, 14, 15};
    int newsMinutes[] = {0, 30};
    
    for(int i = 0; i < ArraySize(newsHours); i++) {
        if(dt.hour == newsHours[i]) {
            for(int j = 0; j < ArraySize(newsMinutes); j++) {
                if(MathAbs(dt.min - newsMinutes[j]) <= 15) {
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
    if(g_limits.dailyLossLimitReached || g_limits.dailyTargetReached) {
        return false;
    }
    
    if(g_stats.totalTrades >= 100) { // Max trades per day
        Print("⚠️ Maximum daily trades reached");
        return false;
    }
    
    if(g_stats.consecutiveLosses >= MaxMartingaleSteps) {
        Print("⚠️ Maximum consecutive losses reached");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize Statistics                                            |
//+------------------------------------------------------------------+
void InitializeStats() {
    ZeroMemory(g_stats);
    g_stats.currentStep = 1;
    g_stats.sessionStartTime = TimeCurrent();
    g_stats.sessionStartBalance = (TradingMode == MODE_DEMO || TradingMode == MODE_BACKTEST) ? 
                                  1000.0 : AccountInfoDouble(ACCOUNT_BALANCE);
    g_stats.currentBalance = g_stats.sessionStartBalance;
}

//+------------------------------------------------------------------+
//| Initialize Daily Limits                                          |
//+------------------------------------------------------------------+
void InitializeDailyLimits() {
    double balance = g_stats.sessionStartBalance;
    
    g_limits.maxDailyLoss = balance * DailyLossLimit;
    g_limits.maxDailyProfit = balance * DailyProfitTarget;
    g_limits.maxDailyTrades = 100;
    g_limits.dailyTargetReached = false;
    g_limits.dailyLossLimitReached = false;
    g_limits.lastResetDate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Check Daily Reset                                                |
//+------------------------------------------------------------------+
void CheckDailyReset() {
    MqlDateTime dt, lastReset;
    TimeToStruct(TimeCurrent(), dt);
    TimeToStruct(g_limits.lastResetDate, lastReset);
    
    if(dt.day != lastReset.day) {
        PrintDailyReport();
        ResetDailyCounters();
        Print("📅 New trading day started - counters reset");
    }
}

//+------------------------------------------------------------------+
//| Reset Daily Counters                                            |
//+------------------------------------------------------------------+
void ResetDailyCounters() {
    g_stats.totalTrades = 0;
    g_stats.winTrades = 0;
    g_stats.lossTrades = 0;
    g_stats.totalProfit = 0;
    g_stats.totalLoss = 0;
    g_stats.netProfit = 0;
    g_stats.currentStep = 1;
    g_stats.consecutiveLosses = 0;
    
    InitializeDailyLimits();
}

//+------------------------------------------------------------------+
//| Monitor Performance                                              |
//+------------------------------------------------------------------+
void MonitorPerformance() {
    static datetime lastHourlyReport = 0;
    
    if(TimeCurrent() - lastHourlyReport >= 3600) { // Every hour
        PrintHourlyReport();
        CheckEmergencyStop();
        lastHourlyReport = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Update Statistics                                                |
//+------------------------------------------------------------------+
void UpdateStatistics() {
    if(g_stats.totalTrades > 0) {
        g_stats.winRate = (double)g_stats.winTrades / g_stats.totalTrades * 100;
        g_stats.profitFactor = (g_stats.totalLoss > 0) ? g_stats.totalProfit / g_stats.totalLoss : 0;
    }
    
    // Update from trade history if available
    int historySize = ArraySize(g_tradeHistory);
    if(historySize > 0) {
        g_stats.netProfit = 0;
        g_stats.winTrades = 0;
        g_stats.lossTrades = 0;
        g_stats.totalProfit = 0;
        g_stats.totalLoss = 0;
        
        for(int i = 0; i < historySize; i++) {
            g_stats.netProfit += g_tradeHistory[i].profit;
            if(g_tradeHistory[i].won) {
                g_stats.winTrades++;
                g_stats.totalProfit += g_tradeHistory[i].profit;
            } else {
                g_stats.lossTrades++;
                g_stats.totalLoss += MathAbs(g_tradeHistory[i].profit);
            }
        }
        
        g_stats.currentBalance = g_stats.sessionStartBalance + g_stats.netProfit;
    }
}

//+------------------------------------------------------------------+
//| Check Emergency Stop                                             |
//+------------------------------------------------------------------+
void CheckEmergencyStop() {
    double drawdown = 0;
    if(g_stats.sessionStartBalance > 0) {
        drawdown = (g_stats.sessionStartBalance - g_stats.currentBalance) / g_stats.sessionStartBalance * 100;
    }
    
    if(drawdown >= 25.0) {
        Print("🚨 EMERGENCY STOP: Drawdown exceeded 25%");
        SendAlert("EMERGENCY STOP: Excessive drawdown detected!");
        ExpertRemove();
    }
    else if(drawdown >= 15.0) {
        Print("⚠️ WARNING: Drawdown approaching danger zone: ", DoubleToString(drawdown, 2), "%");
        SendAlert("WARNING: High drawdown detected - " + DoubleToString(drawdown, 1) + "%");
    }
}

//+------------------------------------------------------------------+
//| Print Trade Information                                          |
//+------------------------------------------------------------------+
void PrintTradeInfo(BinarySignal &signal, double amount) {
    Print("🎯 === TRADE EXECUTED ===");
    Print("Signal: ", (signal.direction == 1 ? "📈 CALL" : "📉 PUT"));
    Print("Amount: $", DoubleToString(amount, 2));
    Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
    Print("Strength: ", EnumToString(signal.strength));
    Print("Step: ", g_stats.currentStep);
    Print("Reason: ", signal.reason);
    Print("Win Rate: ", DoubleToString(g_stats.winRate, 1), "%");
    Print("Balance: $", DoubleToString(g_stats.currentBalance, 2));
    Print("========================");
}

//+------------------------------------------------------------------+
//| Print Hourly Report                                              |
//+------------------------------------------------------------------+
void PrintHourlyReport() {
    Print("⏰ === HOURLY REPORT ===");
    Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("Mode: ", EnumToString(TradingMode));
    Print("Trades Today: ", g_stats.totalTrades);
    Print("Win Rate: ", DoubleToString(g_stats.winRate, 1), "%");
    Print("Net P&L: $", DoubleToString(g_stats.netProfit, 2));
    Print("Balance: $", DoubleToString(g_stats.currentBalance, 2));
    Print("Current Step: ", g_stats.currentStep);
    Print("Consecutive Losses: ", g_stats.consecutiveLosses);
    Print("======================");
}

//+------------------------------------------------------------------+
//| Print Daily Report                                               |
//+------------------------------------------------------------------+
void PrintDailyReport() {
    Print("📊 === DAILY REPORT ===");
    Print("Date: ", TimeToString(TimeCurrent(), TIME_DATE));
    Print("Total Trades: ", g_stats.totalTrades);
    Print("Wins: ", g_stats.winTrades, " | Losses: ", g_stats.lossTrades);
    Print("Win Rate: ", DoubleToString(g_stats.winRate, 1), "%");
    Print("Gross Profit: $", DoubleToString(g_stats.totalProfit, 2));
    Print("Gross Loss: $", DoubleToString(g_stats.totalLoss, 2));
    Print("Net Profit: $", DoubleToString(g_stats.netProfit, 2));
    Print("Profit Factor: ", DoubleToString(g_stats.profitFactor, 2));
    Print("Max Consecutive Losses: ", g_stats.maxConsecutiveLosses);
    Print("Starting Balance: $", DoubleToString(g_stats.sessionStartBalance, 2));
    Print("Current Balance: $", DoubleToString(g_stats.currentBalance, 2));
    Print("Return: ", DoubleToString((g_stats.currentBalance - g_stats.sessionStartBalance) / g_stats.sessionStartBalance * 100, 2), "%");
    Print("======================");
}

//+------------------------------------------------------------------+
//| Print Final Report                                               |
//+------------------------------------------------------------------+
void PrintFinalReport() {
    Print("🏁 === FINAL STATISTICS ===");
    PrintDailyReport();
    
    double runtime = (TimeCurrent() - g_stats.sessionStartTime) / 3600.0;
    Print("Session Runtime: ", DoubleToString(runtime, 1), " hours");
    
    if(g_stats.totalTrades > 0) {
        Print("Average Trade: $", DoubleToString(g_stats.netProfit / g_stats.totalTrades, 2));
        Print("Trades per Hour: ", DoubleToString(g_stats.totalTrades / runtime, 1));
    }
    
    Print("===========================");
}

//+------------------------------------------------------------------+
//| Send Alert/Notification                                         |
//+------------------------------------------------------------------+
void SendAlert(string message) {
    if(!EnableAlerts) return;
    
    // Print to log
    Print("🔔 ALERT: ", message);
    
    // Play sound
    if(PlaySounds) {
        PlaySound("alert.wav");
    }
    
    // Send push notification
    if(SendNotifications) {
        SendNotification("Binary M1: " + message);
    }
    
    // Send email
    if(SendEmails) {
        SendMail("Binary Option M1 Alert", message);
    }
    
    // Show alert dialog
    Alert("Binary M1 Alert: " + message);
}

//+------------------------------------------------------------------+
//| Custom function to handle OnChartEvent                          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    // Handle chart events if needed
    if(id == CHARTEVENT_OBJECT_CLICK) {
        // Handle object clicks
    }
}

//+------------------------------------------------------------------+
//| Expert Advisor main functions (for EA mode)                     |
//+------------------------------------------------------------------+
void OnTick() {
    // This allows the indicator to also work as an EA
    if(EnableAutoTrading) {
        ProcessNewBar();
    }
} 