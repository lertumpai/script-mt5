//+------------------------------------------------------------------+
//| Binary Option M5 Signal Library - ULTRA ENHANCED VERSION       |
//| Enhanced with advanced filtering to prevent consecutive losses  |
//+------------------------------------------------------------------+
#property copyright "Enhanced Binary M5 Signal Library 2024"
#property version   "2.0"
#property strict

//--- Enhanced Input Parameters
input bool UseAdvancedFilters = true;          // ใช้ฟิลเตอร์ขั้นสูง
input bool UseVolatilityFilter = true;         // ฟิลเตอร์ความผันผวน
input bool UseMarketStructureFilter = true;    // ฟิลเตอร์โครงสร้างตลาด
input bool UseNewsTimeFilter = true;           // หลีกเลี่ยงช่วงข่าว
input double MinTrendStrength = 0.68;          // ความแรงของเทรนด์ขั้นต่ำ M5 (moderate)
input double MaxVolatilityLevel = 2.5;         // ระดับความผันผวนสูงสุด M5 (more tolerance)
input int MaxConsecutiveLosses = 3;            // จำนวนแพ้ติดกันสูงสุด
input int DataIndex = 2; // Bar index for signal calculation (1=live, 2=backtest recommended)

//--- Enums
enum SIGNAL_DIRECTION {
    SIGNAL_NONE = 0,        // No Signal
    SIGNAL_CALL = 1,        // Call Signal
    SIGNAL_PUT = -1         // Put Signal
};

enum SIGNAL_STRENGTH {
    STRENGTH_WEAK = 1,      // Weak Signal
    STRENGTH_MODERATE = 2,  // Moderate Signal
    STRENGTH_STRONG = 3     // Strong Signal
};

enum MARKET_CONDITION {
    MARKET_TRENDING = 1,    // Trending Market
    MARKET_RANGING = 2,     // Ranging Market
    MARKET_VOLATILE = 3,    // High Volatility
    MARKET_UNKNOWN = 0      // Unknown Condition
};

string EnumToStringSignalDirection(SIGNAL_DIRECTION res) {
    switch(res) {
        case SIGNAL_NONE: return "NONE";
        case SIGNAL_CALL: return "CALL";
        case SIGNAL_PUT: return "PUT";
        default: return "UNKNOWN";
    }
}

//--- Enhanced Signal Structure
struct BinarySignal {
    SIGNAL_DIRECTION direction;         // Signal direction
    SIGNAL_STRENGTH strength;           // Signal strength
    double confidence;                  // Confidence level (0-100)
    double totalScore;                  // Combined score
    double trendScore;                  // Trend component score
    double momentumScore;               // Momentum component score
    double oscillatorScore;             // Oscillator component score
    double volumeScore;                 // Volume component score
    double trendStrength;               // Trend strength (0-1)
    double volatilityLevel;             // Current volatility level
    MARKET_CONDITION marketCondition;   // Market condition
    string reason;                      // Signal reason
    datetime timestamp;                 // Signal timestamp
    double entryPrice;                  // Entry price
    bool isValid;                       // Signal validity
    bool m15Confirmed;                  // M15 timeframe confirmation
    bool volumeConfirmed;               // Volume confirmation
    bool adxConfirmed;                  // ADX strength confirmation
    bool marketStructureConfirmed;      // Market structure confirmation
    bool volatilityConfirmed;           // Volatility confirmation
    bool newsTimeConfirmed;             // News time confirmation
    int riskLevel;                      // Risk level (1-5)
};

//--- Enhanced Signal Parameters Structure
struct SignalParameters {
    // Basic Indicator Settings (adjusted for M5)
    int emaFast;
    int emaSlow;
    int rsiPeriod;
    int macdFast;
    int macdSlow;
    int macdSignal;
    int stochK;
    int stochD;
    int stochSlowing;
    int bbPeriod;
    double bbDeviation;
    int adxPeriod;
    int volumeMAPeriod;
    
    // Enhanced Thresholds (Stricter for M5)
    double minConfidence;
    double strongSignalThreshold;
    double moderateSignalThreshold;
    double weakSignalThreshold;
    
    // Advanced Filters
    bool useMultiTimeframe;
    bool useVolumeFilter;
    bool useADXFilter;
    double minADXLevel;
    double maxADXLevel;              // Maximum ADX (avoid over-trending)
    
    // Volatility Settings
    int atrPeriod;
    double minATR;
    double maxATR;
    
    // Market Structure
    int swingPeriod;
    double minSwingSize;
    
    // Risk Management
    int maxConsecutiveLosses;
    double dailyLossLimit;
    bool useSessionFilter;
};

//--- Enhanced Global Variables for Indicators
int g_emaFast_handle = INVALID_HANDLE;
int g_emaSlow_handle = INVALID_HANDLE;
int g_emaFastM15_handle = INVALID_HANDLE;
int g_emaSlowM15_handle = INVALID_HANDLE;
int g_rsi_handle = INVALID_HANDLE;
int g_macd_handle = INVALID_HANDLE;
int g_stoch_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;
int g_adx_handle = INVALID_HANDLE;
int g_atr_handle = INVALID_HANDLE;

// Enhanced Market analysis variables
double g_currentATR = 0.0;
double g_avgATR = 0.0;
MARKET_CONDITION g_marketCondition = MARKET_UNKNOWN;
int g_consecutiveLosses = 0;

bool g_initialized = false;
SignalParameters g_params;

//+------------------------------------------------------------------+
//| Initialize Signal System (overloaded for easy use)              |
//+------------------------------------------------------------------+
bool InitializeBinarySignalSystemM5(string symbol = "") {
    return InitializeBinarySignalSystemM5(symbol, false, g_params);
}

//+------------------------------------------------------------------+
//| Initialize Signal System                                         |
//+------------------------------------------------------------------+
bool InitializeBinarySignalSystemM5(string symbol, bool useCustomParams, SignalParameters &customParams) {
    // Use current symbol if not specified
    if(symbol == "") symbol = Symbol();
    
    // Set default parameters if not provided
    if(!useCustomParams) {
        SetDefaultParametersM5();
    } else {
        g_params = customParams;
    }
    
    // Initialize M5 indicators
    g_emaFast_handle = iMA(symbol, PERIOD_M5, g_params.emaFast, 0, MODE_EMA, PRICE_CLOSE);
    g_emaSlow_handle = iMA(symbol, PERIOD_M5, g_params.emaSlow, 0, MODE_EMA, PRICE_CLOSE);
    g_rsi_handle = iRSI(symbol, PERIOD_M5, g_params.rsiPeriod, PRICE_CLOSE);
    g_macd_handle = iMACD(symbol, PERIOD_M5, g_params.macdFast, g_params.macdSlow, g_params.macdSignal, PRICE_CLOSE);
    g_stoch_handle = iStochastic(symbol, PERIOD_M5, g_params.stochK, g_params.stochD, g_params.stochSlowing, MODE_SMA, STO_LOWHIGH);
    g_bb_handle = iBands(symbol, PERIOD_M5, g_params.bbPeriod, g_params.bbDeviation, 0, PRICE_CLOSE);
    g_adx_handle = iADX(symbol, PERIOD_M5, g_params.adxPeriod);
    g_atr_handle = iATR(symbol, PERIOD_M5, g_params.atrPeriod);
    
    // Initialize M15 trend confirmation indicators
    if(g_params.useMultiTimeframe) {
        g_emaFastM15_handle = iMA(symbol, PERIOD_M15, g_params.emaFast, 0, MODE_EMA, PRICE_CLOSE);
        g_emaSlowM15_handle = iMA(symbol, PERIOD_M15, g_params.emaSlow, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    // Verify all handles
    if(g_emaFast_handle == INVALID_HANDLE || g_emaSlow_handle == INVALID_HANDLE ||
       g_rsi_handle == INVALID_HANDLE || g_macd_handle == INVALID_HANDLE ||
       g_stoch_handle == INVALID_HANDLE || g_bb_handle == INVALID_HANDLE ||
       g_adx_handle == INVALID_HANDLE || g_atr_handle == INVALID_HANDLE) {
        Print("ERROR: Failed to initialize enhanced M5 indicators");
        return false;
    }
    
    if(g_params.useMultiTimeframe) {
        if(g_emaFastM15_handle == INVALID_HANDLE || g_emaSlowM15_handle == INVALID_HANDLE) {
            Print("ERROR: Failed to initialize M15 indicators");
            return false;
        }
    }

    g_initialized = true;
    Print("✅ Enhanced Binary M5 Signal System initialized successfully for ", symbol);
    return true;
}

//+------------------------------------------------------------------+
//| Set Enhanced Default Parameters for M5                          |
//+------------------------------------------------------------------+
void SetDefaultParametersM5() {
    // OPTIMIZED M5 indicators (balanced stability and responsiveness)
    g_params.emaFast = 13;              // Medium-fast for M5 balance
    g_params.emaSlow = 34;              // Fibonacci-based for M5
    g_params.rsiPeriod = 21;            // Longer RSI for M5 stability
    g_params.macdFast = 12;             // Standard MACD for M5
    g_params.macdSlow = 26;             // Standard MACD for M5
    g_params.macdSignal = 9;            // Standard signal for M5
    g_params.stochK = 21;               // Longer Stochastic for M5
    g_params.stochD = 5;                // More smoothing for M5
    g_params.stochSlowing = 5;          // More smoothing for M5 stability
    g_params.bbPeriod = 24;             // Longer BB for M5 stability
    g_params.bbDeviation = 2.1;         // Slightly wider bands for M5
    g_params.adxPeriod = 18;            // Longer ADX for M5 trend detection
    g_params.volumeMAPeriod = 20;       // Standard volume analysis for M5
    
    // ULTRA STRICT thresholds M5 (emergency performance fix)
    g_params.minConfidence = 90.0;              // Only elite M5 signals
    g_params.strongSignalThreshold = 110.0;     // Super high M5 threshold
    g_params.moderateSignalThreshold = 95.0;    // Very high M5 threshold
    g_params.weakSignalThreshold = 75.0;        // No weak M5 signals
    
    // OPTIMIZED M5 ADX filters (stable trend detection)
    g_params.useADXFilter = true;
    g_params.minADXLevel = 28.0;                // Higher minimum for M5 stability
    g_params.maxADXLevel = 80.0;                // Higher maximum for M5 tolerance
    
    // OPTIMIZED M5 Volatility settings (stable)
    g_params.atrPeriod = 20;                    // Longer ATR for M5 stability
    g_params.minATR = 0.0003;                   // Higher minimum for M5 (avoid noise)
    g_params.maxATR = 0.0120;                   // Higher maximum for M5 (more tolerance)
    
    // OPTIMIZED M5 Market structure (stable swings)
    g_params.swingPeriod = 12;                  // Longer swing detection for M5 stability
    g_params.minSwingSize = 25.0;               // Larger swing requirement for M5
    
    // Other filters
    g_params.useMultiTimeframe = true;
    g_params.useVolumeFilter = true;
    g_params.useSessionFilter = true;
    
    // Risk management
    g_params.maxConsecutiveLosses = MaxConsecutiveLosses;
    g_params.dailyLossLimit = 10.0;             // 10% daily loss limit
}

//+------------------------------------------------------------------+
//| Get Binary Option Signal - Main Function                        |
//+------------------------------------------------------------------+
BinarySignal GetBinarySignalM5(string symbol = "") {
    BinarySignal signal;
    
    // Initialize signal structure
    signal.direction = SIGNAL_NONE;
    signal.strength = STRENGTH_WEAK;
    signal.confidence = 0.0;
    signal.totalScore = 0.0;
    signal.trendScore = 0.0;
    signal.momentumScore = 0.0;
    signal.oscillatorScore = 0.0;
    signal.volumeScore = 0.0;
    signal.reason = "No Signal";
    signal.timestamp = TimeCurrent();
    signal.isValid = false;
    signal.m15Confirmed = false;
    signal.volumeConfirmed = false;
    signal.adxConfirmed = false;
    
    // Use current symbol if not specified
    if(symbol == "") symbol = Symbol();
    
    // Check if system is initialized
    if(!g_initialized) {
        if(!InitializeBinarySignalSystemM5(symbol)) {
            signal.reason = "System not initialized";
            return signal;
        }
    }
    
    // Set entry price
    signal.entryPrice = (SymbolInfoDouble(symbol, SYMBOL_ASK) + SymbolInfoDouble(symbol, SYMBOL_BID)) / 2.0;
    
    // Calculate individual component scores
    signal.trendScore = CalculateTrendScoreM5(symbol);
    signal.momentumScore = CalculateMomentumScoreM5(symbol);
    signal.oscillatorScore = CalculateOscillatorScoreM5(symbol);
    signal.volumeScore = CalculateVolumeScoreM5(symbol);
    
    // EMERGENCY M5: Ultra trend-focused scoring for better performance
    signal.totalScore = (signal.trendScore * 0.65) +    // Even higher trend weight for M5
                       (signal.momentumScore * 0.2) +    // Reduce momentum weight
                       (signal.oscillatorScore * 0.1) +  // Reduce oscillator weight
                       (signal.volumeScore * 0.05);      // Reduce volume weight
    
    // EMERGENCY M5: Add strong trend bonus/penalty (stricter)
    if(signal.trendStrength > 0.75 && MathAbs(signal.trendScore) > 75) {
        signal.totalScore *= 1.4; // Even bigger bonus for strong M5 trending signals
    } else if(signal.trendStrength < 0.65) {
        signal.totalScore *= 0.2; // Massive penalty for weak M5 trends
    }
    signal.confidence = MathAbs(signal.totalScore);
    
    // Apply confirmation filters
    signal.m15Confirmed = CheckM15TrendAlignment(signal.totalScore, symbol);
    signal.adxConfirmed = CheckADXStrengthM5(symbol);
    signal.volumeConfirmed = CheckVolumeConfirmationM5(symbol);
    
    // Determine signal direction and strength
    DetermineSignalDirectionAndStrengthM5(signal);
    
    // Validate signal
    // ULTRA STRICT M5: Use emergency validation for performance fix
    signal.isValid = ValidateUltraSignalM5(signal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| ENHANCED Calculate Trend Score M5 (Advanced Logic)              |
//+------------------------------------------------------------------+
double CalculateTrendScoreM5(string symbol) {
    double emaFast[], emaSlow[], closes[], highs[], lows[];
    
    if(CopyBuffer(g_emaFast_handle, 0, DataIndex, 5, emaFast) <= 0 ||
       CopyBuffer(g_emaSlow_handle, 0, DataIndex, 5, emaSlow) <= 0 ||
       CopyClose(symbol, PERIOD_M5, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M5, DataIndex, 3, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, 3, lows) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    
    // 1. ENHANCED EMA Relationship Analysis (±30 points)
    bool currentCross = (emaFast[0] > emaSlow[0]);
    bool previousCross = (emaFast[1] > emaSlow[1]);
    
    if(currentCross && previousCross) {
        score += 30.0; // Strong bullish trend
    } else if(!currentCross && !previousCross) {
        score -= 30.0; // Strong bearish trend
    } else if(currentCross && !previousCross) {
        score += 20.0; // Fresh bullish crossover
    } else if(!currentCross && previousCross) {
        score -= 20.0; // Fresh bearish crossover
    }
    
    // 2. EMA Momentum and Acceleration (±20 points)
    double emaFastMomentum = emaFast[0] - emaFast[2];
    double emaSlowMomentum = emaSlow[0] - emaSlow[2];
    
    if(currentCross) {
        if(emaFastMomentum > 0 && emaSlowMomentum > 0) {
            score += 20.0; // Both EMAs rising
        } else if(emaFastMomentum > 0) {
            score += 12.0; // Fast EMA rising
        } else if(emaFastMomentum < 0) {
            score -= 8.0; // Fast EMA falling (divergence)
        }
    } else {
        if(emaFastMomentum < 0 && emaSlowMomentum < 0) {
            score -= 20.0; // Both EMAs falling
        } else if(emaFastMomentum < 0) {
            score -= 12.0; // Fast EMA falling
        } else if(emaFastMomentum > 0) {
            score += 8.0; // Fast EMA rising (divergence)
        }
    }
    
    // 3. EMA Distance and Strength (±15 points) - adjusted for M5
    double distance = MathAbs(emaFast[0] - emaSlow[0]) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    double normalizedDistance = MathMin(distance / 100.0, 1.0); // M5 balanced sensitivity
    
    if(currentCross) {
        score += normalizedDistance * 15.0;
    } else {
        score -= normalizedDistance * 15.0;
    }
    
    // 4. Price Action Confirmation (±15 points)
    double currentPrice = closes[0];
    double prevPrice = closes[1];
    
    if(currentCross) {
        if(currentPrice > prevPrice && currentPrice > emaFast[0]) {
            score += 15.0; // Price above EMA and rising
        } else if(currentPrice > emaFast[0]) {
            score += 8.0; // Price above EMA
        } else if(currentPrice < emaFast[0]) {
            score -= 10.0; // Price below fast EMA (weak)
        }
    } else {
        if(currentPrice < prevPrice && currentPrice < emaFast[0]) {
            score -= 15.0; // Price below EMA and falling
        } else if(currentPrice < emaFast[0]) {
            score -= 8.0; // Price below EMA
        } else if(currentPrice > emaFast[0]) {
            score += 10.0; // Price above fast EMA (weak)
        }
    }
    
    // 5. Trend Consistency Check (±10 points)
    int bullishBars = 0;
    for(int i = 0; i < 4; i++) {
        if(emaFast[i] > emaSlow[i]) bullishBars++;
    }
    double consistency = (double)bullishBars / 4.0;
    
    if(currentCross && consistency >= 0.75) {
        score += 10.0; // Strong bullish consistency
    } else if(!currentCross && consistency <= 0.25) {
        score -= 10.0; // Strong bearish consistency
    } else if((currentCross && consistency < 0.5) || (!currentCross && consistency > 0.5)) {
        score -= 5.0; // Inconsistent trend (penalty)
    }
    
    // 6. Higher High / Lower Low Pattern (±10 points)
    if(currentCross) {
        if(highs[0] > highs[1] && lows[0] > lows[2]) {
            score += 10.0; // Higher highs and higher lows
        } else if(highs[0] < highs[1]) {
            score -= 5.0; // Lower high in uptrend
        }
    } else {
        if(lows[0] < lows[1] && highs[0] < highs[2]) {
            score -= 10.0; // Lower lows and lower highs
        } else if(lows[0] > lows[1]) {
            score += 5.0; // Higher low in downtrend
        }
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| ENHANCED Calculate Momentum Score M5 (Advanced Analysis)        |
//+------------------------------------------------------------------+
double CalculateMomentumScoreM5(string symbol) {
    double rsi[], macdMain[], macdSignal[], closes[], highs[], lows[];
    
    if(CopyBuffer(g_rsi_handle, 0, DataIndex, 5, rsi) <= 0 ||
       CopyBuffer(g_macd_handle, 0, DataIndex, 5, macdMain) <= 0 ||
       CopyBuffer(g_macd_handle, 1, DataIndex, 5, macdSignal) <= 0 ||
       CopyClose(symbol, PERIOD_M5, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M5, DataIndex, 5, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, 5, lows) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    
    // 1. ENHANCED RSI Analysis with Divergence (±25 points)
    double rsiMomentum = rsi[0] - rsi[2];
    double priceMomentum = closes[0] - closes[2];
    
    // RSI Level and Direction
    if(rsi[0] > 50 && rsi[0] < 70 && rsi[0] > rsi[1]) {
        score += 20.0; // Bullish momentum in healthy range
    } else if(rsi[0] < 50 && rsi[0] > 30 && rsi[0] < rsi[1]) {
        score -= 20.0; // Bearish momentum in healthy range
    } else if(rsi[0] >= 70) {
        score -= 12.0; // Overbought penalty (stronger)
    } else if(rsi[0] <= 30) {
        score += 12.0; // Oversold bonus (stronger)
    }
    
    // RSI Divergence Detection
    if(priceMomentum > 0 && rsiMomentum < 0) {
        score -= 8.0; // Bearish divergence
    } else if(priceMomentum < 0 && rsiMomentum > 0) {
        score += 8.0; // Bullish divergence
    } else if(priceMomentum > 0 && rsiMomentum > 0) {
        score += 5.0; // Momentum confluence
    } else if(priceMomentum < 0 && rsiMomentum < 0) {
        score -= 5.0; // Momentum confluence
    }
    
    // 2. ADVANCED MACD Analysis (±25 points)
    double macdHistogram = macdMain[0] - macdSignal[0];
    double prevHistogram = macdMain[1] - macdSignal[1];
    bool macdBullish = (macdMain[0] > macdSignal[0]);
    bool macdRising = (macdMain[0] > macdMain[1]);
    
    // MACD Signal Line Cross
    if(macdBullish && !((macdMain[1] > macdSignal[1]))) {
        score += 15.0; // Fresh bullish cross
    } else if(!macdBullish && (macdMain[1] > macdSignal[1])) {
        score -= 15.0; // Fresh bearish cross
    } else if(macdBullish && macdRising) {
        score += 12.0; // Sustained bullish momentum
    } else if(!macdBullish && !macdRising) {
        score -= 12.0; // Sustained bearish momentum
    }
    
    // MACD Histogram Analysis
    if(macdHistogram > 0 && macdHistogram > prevHistogram) {
        score += 8.0; // Increasing bullish momentum
    } else if(macdHistogram < 0 && macdHistogram < prevHistogram) {
        score -= 8.0; // Increasing bearish momentum
    } else if(macdHistogram > 0 && macdHistogram < prevHistogram) {
        score -= 4.0; // Weakening bullish momentum
    } else if(macdHistogram < 0 && macdHistogram > prevHistogram) {
        score += 4.0; // Weakening bearish momentum
    }
    
    // MACD Zero Line Analysis
    if(macdMain[0] > 0 && macdSignal[0] > 0 && macdBullish) {
        score += 5.0; // Strong bullish position
    } else if(macdMain[0] < 0 && macdSignal[0] < 0 && !macdBullish) {
        score -= 5.0; // Strong bearish position
    }
    
    // 3. Price Momentum Analysis (±15 points)
    double shortMomentum = closes[0] - closes[1]; // 1-bar momentum
    double mediumMomentum = closes[0] - closes[3]; // 3-bar momentum
    
    if(shortMomentum > 0 && mediumMomentum > 0) {
        score += 15.0; // Consistent bullish momentum
    } else if(shortMomentum < 0 && mediumMomentum < 0) {
        score -= 15.0; // Consistent bearish momentum
    } else if(shortMomentum > 0 && mediumMomentum < 0) {
        score += 8.0; // Short-term bullish reversal
    } else if(shortMomentum < 0 && mediumMomentum > 0) {
        score -= 8.0; // Short-term bearish reversal
    }
    
    // 4. Momentum Acceleration (±10 points)
    double momentum1 = closes[0] - closes[1];
    double momentum2 = closes[1] - closes[2];
    double momentum3 = closes[2] - closes[3];
    
    if(momentum1 > momentum2 && momentum2 > momentum3 && momentum1 > 0) {
        score += 10.0; // Accelerating bullish momentum
    } else if(momentum1 < momentum2 && momentum2 < momentum3 && momentum1 < 0) {
        score -= 10.0; // Accelerating bearish momentum
    } else if(momentum1 < momentum2 && momentum1 > 0) {
        score -= 5.0; // Decelerating bullish momentum
    } else if(momentum1 > momentum2 && momentum1 < 0) {
        score += 5.0; // Decelerating bearish momentum
    }
    
    // 5. Volatility-Adjusted Momentum (±5 points)
    double avgRange = 0;
    for(int i = 0; i < 3; i++) {
        avgRange += (highs[i] - lows[i]);
    }
    avgRange /= 3.0;
    
    double currentRange = highs[0] - lows[0];
    if(currentRange > avgRange * 1.2) {
        if(closes[0] > (highs[0] + lows[0]) / 2) {
            score += 5.0; // High volatility, bullish close
        } else {
            score -= 5.0; // High volatility, bearish close
        }
    } else if(currentRange < avgRange * 0.8) {
        score -= 2.0; // Low volatility penalty
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| ENHANCED Calculate Oscillator Score M5 (Advanced Patterns)      |
//+------------------------------------------------------------------+
double CalculateOscillatorScoreM5(string symbol) {
    double stochK[], stochD[], bbUpper[], bbMiddle[], bbLower[];
    double closes[], highs[], lows[], opens[];
    
    if(CopyBuffer(g_stoch_handle, 0, DataIndex, 5, stochK) <= 0 ||
       CopyBuffer(g_stoch_handle, 1, DataIndex, 5, stochD) <= 0 ||
       CopyBuffer(g_bb_handle, 0, DataIndex, 10, bbUpper) <= 0 ||
       CopyBuffer(g_bb_handle, 1, DataIndex, 10, bbMiddle) <= 0 ||
       CopyBuffer(g_bb_handle, 2, DataIndex, 10, bbLower) <= 0 ||
       CopyClose(symbol, PERIOD_M5, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M5, DataIndex, 5, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, 5, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M5, DataIndex, 5, opens) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    double closePrice = closes[0];
    double prevClose = closes[1];
    
    // 1. ADVANCED Stochastic Analysis (±20 points)
    bool stochBullish = (stochK[0] > stochD[0]);
    bool prevStochBullish = (stochK[1] > stochD[1]);
    double stochMomentum = stochK[0] - stochK[2];
    
    // Stochastic Cross Analysis
    if(stochBullish && !prevStochBullish && stochK[0] < 80) {
        if(stochK[0] < 20) {
            score += 20.0; // Bullish cross from oversold
        } else if(stochK[0] < 50) {
            score += 15.0; // Bullish cross in lower half
        } else {
            score += 10.0; // Bullish cross in upper half
        }
    } else if(!stochBullish && prevStochBullish && stochK[0] > 20) {
        if(stochK[0] > 80) {
            score -= 20.0; // Bearish cross from overbought
        } else if(stochK[0] > 50) {
            score -= 15.0; // Bearish cross in upper half
        } else {
            score -= 10.0; // Bearish cross in lower half
        }
    }
    
    // Stochastic Momentum and Divergence
    double priceMomentum = closePrice - closes[2];
    if(stochBullish) {
        if(stochMomentum > 0 && priceMomentum > 0) {
            score += 8.0; // Momentum confluence
        } else if(stochMomentum < 0 && priceMomentum > 0) {
            score -= 5.0; // Bearish divergence in bullish market
        }
    } else {
        if(stochMomentum < 0 && priceMomentum < 0) {
            score -= 8.0; // Momentum confluence
        } else if(stochMomentum > 0 && priceMomentum < 0) {
            score += 5.0; // Bullish divergence in bearish market
        }
    }
    
    // Stochastic Extreme Levels with Time Analysis
    if(stochK[0] >= 80) {
        int overboughtBars = 0;
        for(int i = 0; i < 5; i++) {
            if(stochK[i] >= 80) overboughtBars++;
        }
        if(overboughtBars >= 3) {
            score -= 12.0; // Extended overbought (dangerous)
        } else {
            score -= 6.0; // Fresh overbought
        }
    } else if(stochK[0] <= 20) {
        int oversoldBars = 0;
        for(int i = 0; i < 5; i++) {
            if(stochK[i] <= 20) oversoldBars++;
        }
        if(oversoldBars >= 3) {
            score += 12.0; // Extended oversold (opportunity)
        } else {
            score += 6.0; // Fresh oversold
        }
    }
    
    // 2. ADVANCED Bollinger Bands Analysis (±25 points)
    double bbWidth = bbUpper[0] - bbLower[0];
    double bbPosition = (closePrice - bbLower[0]) / bbWidth;
    
    // Calculate BB Width Trend (Expansion/Contraction)
    double avgBBWidth = 0;
    for(int i = 1; i < 10; i++) {
        avgBBWidth += (bbUpper[i] - bbLower[i]);
    }
    avgBBWidth /= 9.0;
    
    bool bbExpanding = (bbWidth > avgBBWidth * 1.1);
    bool bbContracting = (bbWidth < avgBBWidth * 0.9);
    
    // BB Position Analysis
    if(bbPosition >= 0.9) {
        if(bbExpanding) {
            score -= 15.0; // Near upper band with expansion (very bearish)
        } else {
            score -= 8.0; // Near upper band
        }
    } else if(bbPosition <= 0.1) {
        if(bbExpanding) {
            score += 15.0; // Near lower band with expansion (very bullish)
        } else {
            score += 8.0; // Near lower band
        }
    } else if(bbPosition > 0.3 && bbPosition < 0.7) {
        // Price in middle zone - good for trend continuation
        if(closePrice > prevClose) {
            if(bbExpanding) {
                score += 12.0; // Rising price with expansion
            } else {
                score += 8.0; // Rising price
            }
        } else {
            if(bbExpanding) {
                score -= 12.0; // Falling price with expansion
            } else {
                score -= 8.0; // Falling price
            }
        }
    }
    
    // BB Squeeze Detection and Breakout Prediction
    if(bbContracting) {
        // Potential breakout setup
        double momentum = closePrice - closes[3];
        if(MathAbs(momentum) > (bbWidth * 0.1)) {
            if(momentum > 0) {
                score += 10.0; // Bullish breakout from squeeze
            } else {
                score -= 10.0; // Bearish breakout from squeeze
            }
        } else {
            score += 3.0; // Squeeze with potential (slight bullish bias)
        }
    }
    
    // BB Middle Line Analysis
    if(closePrice > bbMiddle[0] && prevClose <= bbMiddle[0]) {
        score += 8.0; // Fresh break above middle
    } else if(closePrice < bbMiddle[0] && prevClose >= bbMiddle[0]) {
        score -= 8.0; // Fresh break below middle
    } else if(closePrice > bbMiddle[0] && bbMiddle[0] > bbMiddle[1]) {
        score += 5.0; // Above rising middle line
    } else if(closePrice < bbMiddle[0] && bbMiddle[0] < bbMiddle[1]) {
        score -= 5.0; // Below falling middle line
    }
    
    // 3. Price Action vs Oscillators Confluence (±10 points)
    bool priceRising = (closePrice > opens[0] && closePrice > closes[1]);
    bool priceFalling = (closePrice < opens[0] && closePrice < closes[1]);
    
    if(priceRising && stochBullish && bbPosition > 0.3 && bbPosition < 0.8) {
        score += 10.0; // Perfect bullish confluence
    } else if(priceFalling && !stochBullish && bbPosition < 0.7 && bbPosition > 0.2) {
        score -= 10.0; // Perfect bearish confluence
    } else if(priceRising && !stochBullish) {
        score -= 5.0; // Price/oscillator divergence
    } else if(priceFalling && stochBullish) {
        score += 5.0; // Price/oscillator divergence
    }
    
    // 4. Candle Pattern Enhancement (±5 points)
    double bodySize = MathAbs(closePrice - opens[0]);
    double candleRange = highs[0] - lows[0];
    double bodyRatio = (candleRange > 0) ? bodySize / candleRange : 0;
    
    if(bodyRatio > 0.7) { // Strong body
        if(closePrice > opens[0] && stochBullish) {
            score += 5.0; // Strong bullish candle with stoch support
        } else if(closePrice < opens[0] && !stochBullish) {
            score -= 5.0; // Strong bearish candle with stoch support
        }
    } else if(bodyRatio < 0.3) { // Doji or small body
        score -= 2.0; // Indecision penalty
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| ENHANCED Calculate Volume Score M5 (Advanced VPA Analysis)      |
//+------------------------------------------------------------------+
double CalculateVolumeScoreM5(string symbol) {
    if(!g_params.useVolumeFilter) return 0.0;
    
    // Collect volume and price data
    long volumes[10];
    double closes[10], highs[10], lows[10], opens[10];
    
    bool dataValid = true;
    for(int i = 0; i < 10; i++) {
        volumes[i] = iVolume(symbol, PERIOD_M5, DataIndex + i);
        if(volumes[i] <= 0) dataValid = false;
    }
    
    if(!dataValid || 
       CopyClose(symbol, PERIOD_M5, DataIndex, 10, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M5, DataIndex, 10, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, 10, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M5, DataIndex, 10, opens) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    long currentVolume = volumes[0];
    long prevVolume = volumes[1];
    double currentClose = closes[0];
    double prevClose = closes[1];
    
    // Calculate volume statistics
    long totalVolume = 0;
    long maxVolume = 0;
    long minVolume = volumes[0];
    
    for(int i = 1; i < 10; i++) { // Skip current bar for average
        totalVolume += volumes[i];
        if(volumes[i] > maxVolume) maxVolume = volumes[i];
        if(volumes[i] < minVolume) minVolume = volumes[i];
    }
    
    double avgVolume = (double)totalVolume / 9.0;
    double volumeRatio = (avgVolume > 0) ? (double)currentVolume / avgVolume : 1.0;
    
    // 1. VOLUME LEVEL ANALYSIS (±15 points)
    if(currentVolume > avgVolume * 2.2) {      // Adjusted for M5
        score += 15.0; // Extremely high volume
    } else if(currentVolume > avgVolume * 1.7) {
        score += 12.0; // Very high volume
    } else if(currentVolume > avgVolume * 1.4) {
        score += 8.0;  // High volume
    } else if(currentVolume > avgVolume * 0.9) {
        score += 3.0;  // Average volume
    } else if(currentVolume < avgVolume * 0.5) {
        score -= 8.0;  // Very low volume (suspicious)
    } else {
        score -= 3.0;  // Below average volume
    }
    
    // 2. VOLUME PRICE ANALYSIS (±20 points)
    double priceRange = highs[0] - lows[0];
    double priceChange = currentClose - opens[0];
    double priceChangePercent = (opens[0] != 0) ? (priceChange / opens[0]) * 100 : 0;
    
    // Volume vs Price Movement Correlation
    if(MathAbs(priceChangePercent) > 0.08) { // Adjusted for M5
        if(currentVolume > avgVolume * 1.5) {  // Adjusted for M5
            if(priceChange > 0) {
                score += 20.0; // High volume bullish move
            } else {
                score -= 20.0; // High volume bearish move
            }
        } else if(currentVolume < avgVolume * 0.8) {
            if(priceChange > 0) {
                score -= 10.0; // Low volume bullish move (weak)
            } else {
                score += 10.0; // Low volume bearish move (weak)
            }
        }
    }
    
    // Price close position within range
    double closePosition = (priceRange > 0) ? (currentClose - lows[0]) / priceRange : 0.5;
    if(currentVolume > avgVolume * 1.3) {
        if(closePosition > 0.7) {
            score += 10.0; // High volume with close near high
        } else if(closePosition < 0.3) {
            score -= 10.0; // High volume with close near low
        }
    }
    
    // 3. VOLUME MOMENTUM ANALYSIS (±15 points)
    double volumeMomentum = (double)currentVolume - (double)prevVolume;
    double volumeChangePercent = (prevVolume > 0) ? (volumeMomentum / prevVolume) * 100 : 0;
    
    if(volumeChangePercent > 60) {            // Adjusted for M5
        if(currentClose > prevClose) {
            score += 15.0; // Increasing volume with price up
        } else {
            score -= 12.0; // Increasing volume with price down
        }
    } else if(volumeChangePercent > 25) {     // Adjusted for M5
        if(currentClose > prevClose) {
            score += 8.0; // Moderate volume increase with price up
        } else {
            score -= 6.0; // Moderate volume increase with price down
        }
    } else if(volumeChangePercent < -35) {    // Adjusted for M5
        score -= 5.0; // Decreasing volume (lack of interest)
    }
    
    // 4. VOLUME DIVERGENCE ANALYSIS (±15 points)
    // Compare volume trend vs price trend over 5 bars
    double priceDirection = currentClose - closes[4];
    double volumeTrend = 0;
    
    for(int i = 0; i < 4; i++) {
        if(volumes[i] > volumes[i + 1]) volumeTrend += 1.0;
        else volumeTrend -= 1.0;
    }
    volumeTrend /= 4.0; // Normalize to -1 to +1
    
    if(priceDirection > 0 && volumeTrend > 0.5) {
        score += 15.0; // Price up with volume confirmation
    } else if(priceDirection < 0 && volumeTrend > 0.5) {
        score -= 15.0; // Price down with volume confirmation
    } else if(priceDirection > 0 && volumeTrend < -0.5) {
        score -= 8.0; // Bullish divergence (price up, volume down)
    } else if(priceDirection < 0 && volumeTrend < -0.5) {
        score += 8.0; // Bearish divergence (price down, volume down)
    }
    
    // 5. ACCUMULATION/DISTRIBUTION ANALYSIS (±10 points)
    double adValue = 0;
    for(int i = 0; i < 5; i++) {
        double clv = ((closes[i] - lows[i]) - (highs[i] - closes[i])) / (highs[i] - lows[i]);
        if(highs[i] == lows[i]) clv = 0; // Avoid division by zero
        adValue += clv * volumes[i];
    }
    
    if(adValue > 0) {
        score += 10.0; // Accumulation pattern
    } else if(adValue < 0) {
        score -= 10.0; // Distribution pattern
    }
    
    // 6. VOLUME SPIKE ANALYSIS (±10 points)
    if(currentVolume > maxVolume && currentVolume > avgVolume * 2.2) { // Adjusted for M5
        // Volume spike - very significant
        if(MathAbs(priceChangePercent) > 0.15) { // Adjusted for M5
            if(priceChange > 0) {
                score += 10.0; // Bullish volume spike
            } else {
                score -= 10.0; // Bearish volume spike
            }
        } else {
            score -= 5.0; // Volume spike without price movement (caution)
        }
    }
    
    // 7. VOLUME CONSISTENCY CHECK (±5 points)
    int aboveAvgCount = 0;
    for(int i = 0; i < 5; i++) {
        if(volumes[i] > avgVolume) aboveAvgCount++;
    }
    
    double consistencyRatio = (double)aboveAvgCount / 5.0;
    if(consistencyRatio >= 0.8) {
        score += 5.0; // Consistently high volume
    } else if(consistencyRatio <= 0.2) {
        score -= 5.0; // Consistently low volume
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Check M15 Trend Alignment                                        |
//+------------------------------------------------------------------+
bool CheckM15TrendAlignment(double m5Signal, string symbol) {
    if(!g_params.useMultiTimeframe) return true;
    
    double emaFastM15[], emaSlowM15[];
    
    // For M15 confirmation, use index based on M5 to M15 ratio (approximately 1/3)
    int m15Index = (DataIndex > 1) ? (DataIndex / 3) + 1 : 1;
    
    if(CopyBuffer(g_emaFastM15_handle, 0, m15Index, 1, emaFastM15) <= 0 ||
       CopyBuffer(g_emaSlowM15_handle, 0, m15Index, 1, emaSlowM15) <= 0) {
        return false;
    }
    
    bool m15Bullish = (emaFastM15[0] > emaSlowM15[0]);
    bool m15Bearish = (emaFastM15[0] < emaSlowM15[0]);
    
    if(m5Signal > 0 && m15Bullish) return true;
    if(m5Signal < 0 && m15Bearish) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check ADX Strength                                               |
//+------------------------------------------------------------------+
bool CheckADXStrengthM5(string symbol) {
    if(!g_params.useADXFilter) return true;
    
    double adx[];
    
    if(CopyBuffer(g_adx_handle, 0, DataIndex, 1, adx) <= 0) {
        return false;
    }
    
    return (adx[0] > g_params.minADXLevel);
}

//+------------------------------------------------------------------+
//| Check Volume Confirmation                                        |
//+------------------------------------------------------------------+
bool CheckVolumeConfirmationM5(string symbol) {
    if(!g_params.useVolumeFilter) return true;
    
    // Get current volume
    long currentVolume = iVolume(symbol, PERIOD_M5, DataIndex);
    
    // Calculate average volume from recent 8 bars (adjusted for M5)
    long totalVolume = 0;
    int validBars = 0;
    
    for(int i = DataIndex; i <= DataIndex + 7; i++) {
        long barVolume = iVolume(symbol, PERIOD_M5, i);
        if(barVolume > 0) {
            totalVolume += barVolume;
            validBars++;
        }
    }
    
    if(validBars == 0) return false;
    
    double avgVolume = (double)totalVolume / validBars;
    
    return (currentVolume > avgVolume * 1.2); // Higher threshold for M5
}

//+------------------------------------------------------------------+
//| ENHANCED Determine Signal Direction and Strength M5             |
//+------------------------------------------------------------------+
void DetermineSignalDirectionAndStrengthM5(BinarySignal &signal) {
    double totalScore = signal.totalScore;
    
    // Count confirmations for enhanced validation
    int confirmations = 0;
    if(signal.m15Confirmed) confirmations++;
    if(signal.adxConfirmed) confirmations++;
    if(signal.volumeConfirmed) confirmations++;
    if(signal.marketStructureConfirmed) confirmations++;
    if(signal.volatilityConfirmed) confirmations++;
    if(signal.newsTimeConfirmed) confirmations++;
    
    // ENHANCED: Stricter criteria to prevent consecutive losses
    int requiredConfirmations = 4; // Need 4/6 confirmations minimum
    
    // Determine direction and strength with enhanced criteria
    if(MathAbs(totalScore) >= g_params.strongSignalThreshold && confirmations >= requiredConfirmations) {
        signal.direction = (totalScore > 0) ? SIGNAL_CALL : SIGNAL_PUT;
        signal.strength = STRENGTH_STRONG;
        signal.reason = StringFormat("STRONG %s M5 - Score: %.1f, Confirmations: %d/6", 
                                   (totalScore > 0) ? "CALL" : "PUT", totalScore, confirmations);
    }
    else if(MathAbs(totalScore) >= g_params.moderateSignalThreshold && confirmations >= (requiredConfirmations - 1)) {
        signal.direction = (totalScore > 0) ? SIGNAL_CALL : SIGNAL_PUT;
        signal.strength = STRENGTH_MODERATE;
        signal.reason = StringFormat("MODERATE %s M5 - Score: %.1f, Confirmations: %d/6", 
                                   (totalScore > 0) ? "CALL" : "PUT", totalScore, confirmations);
    }
    else {
        signal.direction = SIGNAL_NONE;
        signal.strength = STRENGTH_WEAK;
        signal.reason = StringFormat("NO SIGNAL M5 - Score: %.1f, Confirmations: %d/6 (Need %d+)", 
                                   totalScore, confirmations, requiredConfirmations);
    }
}

//+------------------------------------------------------------------+
//| Validate Signal                                                  |
//+------------------------------------------------------------------+
bool ValidateSignalM5(BinarySignal &signal) {
    // Basic validation
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < g_params.minConfidence) return false;
    
    // Confirmation requirements
    if(g_params.useMultiTimeframe && !signal.m15Confirmed) return false;
    if(g_params.useADXFilter && !signal.adxConfirmed) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get Signal Strength as String                                   |
//+------------------------------------------------------------------+
string SignalStrengthToStringM5(SIGNAL_STRENGTH strength) {
    switch(strength) {
        case STRENGTH_WEAK:     return "WEAK";
        case STRENGTH_MODERATE: return "MODERATE";
        case STRENGTH_STRONG:   return "STRONG";
        default:                return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get Signal Direction as String                                  |
//+------------------------------------------------------------------+
string SignalDirectionToStringM5(SIGNAL_DIRECTION direction) {
    switch(direction) {
        case SIGNAL_CALL:   return "CALL";
        case SIGNAL_PUT:    return "PUT";
        case SIGNAL_NONE:   return "NONE";
        default:            return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Print Signal Information                                         |
//+------------------------------------------------------------------+
void PrintSignalInfoM5(BinarySignal &signal) {
    Print("=== BINARY M5 SIGNAL INFO ===");
    Print("Direction: ", SignalDirectionToStringM5(signal.direction));
    Print("Strength: ", SignalStrengthToStringM5(signal.strength));
    Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
    Print("Total Score: ", DoubleToString(signal.totalScore, 1));
    Print("Components: T:", DoubleToString(signal.trendScore, 1), 
          " M:", DoubleToString(signal.momentumScore, 1),
          " O:", DoubleToString(signal.oscillatorScore, 1),
          " V:", DoubleToString(signal.volumeScore, 1));
    Print("Confirmations: M15:", signal.m15Confirmed, " ADX:", signal.adxConfirmed, " Vol:", signal.volumeConfirmed);
    Print("Valid: ", signal.isValid);
    Print("Reason: ", signal.reason);
    Print("Timestamp: ", TimeToString(signal.timestamp, TIME_DATE|TIME_SECONDS));
    Print("Entry Price: ", DoubleToString(signal.entryPrice, 5));
    Print("============================");
}

//+------------------------------------------------------------------+
//| Update Signal Parameters                                         |
//+------------------------------------------------------------------+
void UpdateSignalParametersM5(const SignalParameters &newParams) {
    g_params = newParams;
    g_initialized = false; // Force re-initialization with new parameters
}

//+------------------------------------------------------------------+
//| Get Current Signal Parameters                                    |
//+------------------------------------------------------------------+
SignalParameters GetSignalParametersM5() {
    return g_params;
}

//+------------------------------------------------------------------+
//| Cleanup Function                                                 |
//+------------------------------------------------------------------+
void CleanupBinarySignalSystemM5() {
    if(g_emaFast_handle != INVALID_HANDLE) IndicatorRelease(g_emaFast_handle);
    if(g_emaSlow_handle != INVALID_HANDLE) IndicatorRelease(g_emaSlow_handle);
    if(g_emaFastM15_handle != INVALID_HANDLE) IndicatorRelease(g_emaFastM15_handle);
    if(g_emaSlowM15_handle != INVALID_HANDLE) IndicatorRelease(g_emaSlowM15_handle);
    if(g_rsi_handle != INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
    if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
    if(g_stoch_handle != INVALID_HANDLE) IndicatorRelease(g_stoch_handle);
    if(g_bb_handle != INVALID_HANDLE) IndicatorRelease(g_bb_handle);
    if(g_adx_handle != INVALID_HANDLE) IndicatorRelease(g_adx_handle);
    if(g_atr_handle != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
    
    g_initialized = false;
    Print("Enhanced Binary M5 Signal System cleaned up");
}

//+------------------------------------------------------------------+
//| Enhanced Quick Signal Check M5                                  |
//+------------------------------------------------------------------+
int GetQuickSignalM5(string symbol = "", double minConfidence = 75.0) { // Increased default
    BinarySignal signal = GetBinarySignalM5(symbol);
    
    if(signal.isValid && signal.confidence >= minConfidence && signal.riskLevel <= 3) {
        return (int)signal.direction;
    }
    
    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Check if Signal System is Ready                                 |
//+------------------------------------------------------------------+
bool IsSignalSystemReadyM5() {
    return g_initialized;
}

//+------------------------------------------------------------------+
//| ENHANCED FUNCTIONS FOR M5 TO PREVENT CONSECUTIVE LOSSES        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Analyze Market Condition M5                                     |
//+------------------------------------------------------------------+
void AnalyzeMarketConditionM5(string symbol, BinarySignal &signal) {
    // Get ATR for volatility analysis
    double atr[];
    if(CopyBuffer(g_atr_handle, 0, DataIndex, 14, atr) > 0) {
        g_currentATR = atr[0];
        
        // Calculate average ATR
        double sum = 0;
        for(int i = 0; i < 14; i++) {
            sum += atr[i];
        }
        g_avgATR = sum / 14.0;
        
        signal.volatilityLevel = g_currentATR / g_avgATR;
    }
    
    // Determine market condition based on ADX
    double adx[];
    if(CopyBuffer(g_adx_handle, 0, DataIndex, 1, adx) > 0) {
        if(adx[0] > 35) {              // Adjusted for M5
            g_marketCondition = MARKET_TRENDING;
        } else if(adx[0] < 18) {       // Adjusted for M5
            g_marketCondition = MARKET_RANGING;
        } else {
            g_marketCondition = MARKET_UNKNOWN;
        }
        
        // Override if volatility too high
        if(signal.volatilityLevel > 2.2) {  // Adjusted for M5
            g_marketCondition = MARKET_VOLATILE;
        }
    }
    
    signal.marketCondition = g_marketCondition;
    
    // Calculate trend strength
    double emaFast[], emaSlow[];
    if(CopyBuffer(g_emaFast_handle, 0, DataIndex, 10, emaFast) > 0 &&
       CopyBuffer(g_emaSlow_handle, 0, DataIndex, 10, emaSlow) > 0) {
        
        int trendCount = 0;
        for(int i = 0; i < 10; i++) {
            if(emaFast[i] > emaSlow[i]) trendCount++;
        }
        signal.trendStrength = (double)trendCount / 10.0;
        if(signal.trendStrength < 0.5) {
            signal.trendStrength = 1.0 - signal.trendStrength; // For downtrend
        }
    }
}

//+------------------------------------------------------------------+
//| Pre-Filters Check M5 (CRITICAL FOR PREVENTING LOSSES)          |
//+------------------------------------------------------------------+
bool PassPreFiltersM5(BinarySignal &signal) {
    // 1. Market condition filter
    if(UseAdvancedFilters) {
        if(signal.marketCondition == MARKET_VOLATILE) {
            signal.reason = "Market too volatile - avoiding trade";
            return false;
        }
        
        if(signal.marketCondition == MARKET_UNKNOWN) {
            signal.reason = "Unclear market condition";
            return false;
        }
    }
    
    // 2. Volatility filter
    if(UseVolatilityFilter) {
        if(signal.volatilityLevel > MaxVolatilityLevel) {
            signal.reason = "Volatility too high";
            return false;
        }
        
        if(g_currentATR < g_params.minATR) {
            signal.reason = "Volatility too low";
            return false;
        }
    }
    
    // 3. Trend strength filter
    if(signal.trendStrength < MinTrendStrength) {
        signal.reason = "Trend too weak";
        return false;
    }
    
    // 4. News time filter
    if(UseNewsTimeFilter && IsNewsTimeM5()) {
        signal.reason = "News time - avoiding trade";
        return false;
    }
    
    // 5. Session filter
    if(g_params.useSessionFilter && !IsGoodTradingSessionM5()) {
        signal.reason = "Poor trading session";
        return false;
    }
    
    // 6. Consecutive losses filter
    if(g_consecutiveLosses >= g_params.maxConsecutiveLosses) {
        signal.reason = StringFormat("Max consecutive losses reached (%d)", g_consecutiveLosses);
        return false;
    }
    
    // 7. M5 EMERGENCY STOP - Daily performance protection
    CheckDailyPerformanceM5();
    if(g_emergencyStopM5) {
        signal.reason = "M5 Emergency stop activated - poor daily performance";
        return false;
    }
    
    // 8. EMERGENCY: Only trade during BEST M5 sessions
    if(!IsBestTradingSessionM5()) {
        signal.reason = "Outside optimal M5 trading session";
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply Enhanced Confirmations M5                                 |
//+------------------------------------------------------------------+
void ApplyEnhancedConfirmationsM5(BinarySignal &signal, string symbol) {
    // 1. M15 confirmation (enhanced)
    signal.m15Confirmed = CheckEnhancedM15TrendAlignment(signal.totalScore, symbol);
    
    // 2. ADX confirmation with range check
    double adx[];
    if(CopyBuffer(g_adx_handle, 0, DataIndex, 1, adx) > 0) {
        signal.adxConfirmed = (adx[0] >= g_params.minADXLevel && adx[0] <= g_params.maxADXLevel);
    }
    
    // 3. Volume confirmation
    signal.volumeConfirmed = CheckVolumeConfirmationM5(symbol);
    
    // 4. Market structure confirmation
    signal.marketStructureConfirmed = CheckMarketStructureM5(symbol);
    
    // 5. Volatility confirmation
    signal.volatilityConfirmed = (signal.volatilityLevel >= 0.5 && signal.volatilityLevel <= MaxVolatilityLevel);
    
    // 6. News time confirmation
    signal.newsTimeConfirmed = !IsNewsTimeM5();
    
    // Calculate risk level
    signal.riskLevel = CalculateRiskLevelM5(signal);
}

//+------------------------------------------------------------------+
//| Enhanced M15 Trend Alignment Check                              |
//+------------------------------------------------------------------+
bool CheckEnhancedM15TrendAlignment(double m5Signal, string symbol) {
    if(!g_params.useMultiTimeframe) return true;
    
    double emaFastM15[], emaSlowM15[];
    int m15Index = (DataIndex > 1) ? (DataIndex / 3) + 1 : 1;
    
    if(CopyBuffer(g_emaFastM15_handle, 0, m15Index, 3, emaFastM15) <= 0 ||
       CopyBuffer(g_emaSlowM15_handle, 0, m15Index, 3, emaSlowM15) <= 0) {
        return false;
    }
    
    // Check M15 trend direction
    bool m15Bullish = (emaFastM15[0] > emaSlowM15[0]);
    bool m15Bearish = (emaFastM15[0] < emaSlowM15[0]);
    
    // Check M15 trend consistency (more strict)
    bool m15TrendUp = (emaFastM15[0] > emaFastM15[1] && emaFastM15[1] > emaFastM15[2]);
    bool m15TrendDown = (emaFastM15[0] < emaFastM15[1] && emaFastM15[1] < emaFastM15[2]);
    
    if(m5Signal > 0) {
        return (m15Bullish && (m15TrendUp || emaFastM15[0] > emaFastM15[1]));
    } else if(m5Signal < 0) {
        return (m15Bearish && (m15TrendDown || emaFastM15[0] < emaFastM15[1]));
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Market Structure M5                                       |
//+------------------------------------------------------------------+
bool CheckMarketStructureM5(string symbol) {
    if(!UseMarketStructureFilter) return true;
    
    // Check for clear swing highs and lows
    double highs[], lows[];
    int period = g_params.swingPeriod;
    
    if(CopyHigh(symbol, PERIOD_M5, DataIndex, period, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, period, lows) <= 0) {
        return false;
    }
    
    // Find recent swing points
    double maxHigh = highs[ArrayMaximum(highs)];
    double minLow = lows[ArrayMinimum(lows)];
    double swingSize = (maxHigh - minLow) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    return (swingSize >= g_params.minSwingSize);
}

//+------------------------------------------------------------------+
//| Check if it's News Time M5                                      |
//+------------------------------------------------------------------+
bool IsNewsTimeM5() {
    if(!UseNewsTimeFilter) return false;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Avoid major news times (GMT) - same as M1
    if(dt.day_of_week >= 1 && dt.day_of_week <= 5) {
        if((dt.hour >= 13 && dt.hour < 14) || (dt.hour >= 19 && dt.hour < 20)) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if Good Trading Session M5                                |
//+------------------------------------------------------------------+
bool IsGoodTradingSessionM5() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // GMT hours for major sessions
    if(dt.day_of_week >= 1 && dt.day_of_week <= 5) {
        if((dt.hour >= 8 && dt.hour <= 17) || (dt.hour >= 13 && dt.hour <= 22)) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Risk Level M5                                         |
//+------------------------------------------------------------------+
int CalculateRiskLevelM5(BinarySignal &signal) {
    int risk = 1; // Start with low risk
    
    // Increase risk based on various factors
    if(!signal.m15Confirmed) risk++;
    if(!signal.adxConfirmed) risk++;
    if(!signal.volumeConfirmed) risk++;
    if(!signal.marketStructureConfirmed) risk++;
    if(!signal.volatilityConfirmed) risk++;
    if(signal.marketCondition == MARKET_VOLATILE) risk += 2;
    if(signal.trendStrength < 0.65) risk++;  // Adjusted for M5
    
    return MathMin(risk, 5); // Cap at 5
}

//+------------------------------------------------------------------+
//| Enhanced Signal Validation M5 (STRICTER CRITERIA)              |
//+------------------------------------------------------------------+
bool ValidateEnhancedSignalM5(BinarySignal &signal) {
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < g_params.minConfidence) return false;
    if(signal.riskLevel > 3) return false; // Reject high-risk signals
    
    // Count confirmations
    int confirmations = 0;
    if(signal.m15Confirmed) confirmations++;
    if(signal.adxConfirmed) confirmations++;
    if(signal.volumeConfirmed) confirmations++;
    if(signal.marketStructureConfirmed) confirmations++;
    if(signal.volatilityConfirmed) confirmations++;
    if(signal.newsTimeConfirmed) confirmations++;
    
    // Require minimum 4/6 confirmations
    if(confirmations < 4) return false;
    
    // Additional mandatory validations
    if(!signal.m15Confirmed) return false;
    if(!signal.adxConfirmed) return false;
    if(!signal.newsTimeConfirmed) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Track Consecutive Losses M5 (CALL THIS AFTER EACH TRADE)       |
//+------------------------------------------------------------------+
void UpdateConsecutiveLossesM5(bool wasWin) {
    if(wasWin) {
        g_consecutiveLosses = 0;
    } else {
        g_consecutiveLosses++;
    }
    
    // ULTIMATE: Update adaptive learning system
    UpdateAdaptiveLearningM5(wasWin);
}

//+------------------------------------------------------------------+
//| Get Current Consecutive Losses Count M5                         |
//+------------------------------------------------------------------+
int GetConsecutiveLossesCountM5() {
    return g_consecutiveLosses;
}

//+------------------------------------------------------------------+
//| Print Enhanced Signal Information M5                            |
//+------------------------------------------------------------------+
void PrintEnhancedSignalInfoM5(BinarySignal &signal) {
    Print("=== ULTIMATE ENHANCED M5 SIGNAL ===");
    Print("Direction: ", EnumToStringSignalDirection(signal.direction));
    Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
    Print("Total Score: ", DoubleToString(signal.totalScore, 1));
    Print("Risk Level: ", signal.riskLevel, "/5");
    Print("Trend Strength: ", DoubleToString(signal.trendStrength, 2));
    Print("Volatility Level: ", DoubleToString(signal.volatilityLevel, 2));
    Print("Confirmations: M15:", signal.m15Confirmed, " ADX:", signal.adxConfirmed, 
          " Vol:", signal.volumeConfirmed, " Struct:", signal.marketStructureConfirmed);
    Print("Filters: Volatility:", signal.volatilityConfirmed, " News:", signal.newsTimeConfirmed);
    Print("Valid: ", signal.isValid);
    Print("Reason: ", signal.reason);
    Print("Consecutive Losses: ", g_consecutiveLosses);
    
    // ULTIMATE: Show adaptive intelligence metrics
    Print("--- ADAPTIVE INTELLIGENCE M5 ---");
    Print("Adaptive Multiplier: ", DoubleToString(g_adaptiveMultiplierM5, 3));
    Print("Recent Win Rate: ", DoubleToString(g_performanceScoreM5 * 100, 1), "%");
    Print("Recent Trades: ", (g_recentWinsM5 + g_recentLossesM5));
    Print("Market Condition: ", signal.marketCondition);
    Print("====================================");
}

//+------------------------------------------------------------------+
//| ULTIMATE ENHANCEMENT M5: Adaptive Signal Intelligence           |
//+------------------------------------------------------------------+

// EMERGENCY Performance monitoring variables for M5
double g_adaptiveMultiplierM5 = 1.0;
int g_recentWinsM5 = 0;
int g_recentLossesM5 = 0;
int g_adaptivePeriodM5 = 20;
double g_performanceScoreM5 = 0.0;

// CRITICAL: M5 Emergency performance controls
int g_dailyTradesM5 = 0;
int g_dailyWinsM5 = 0;
int g_dailyLossesM5 = 0;
double g_dailyWinRateM5 = 0.0;
int g_emergencyStopLossesM5 = 4;         // Stop after 4 M5 daily losses (stricter)
bool g_emergencyStopM5 = false;
datetime g_lastTradeDayM5 = 0;

//+------------------------------------------------------------------+
//| Adaptive Signal Enhancement M5 (Machine Learning-like)          |
//+------------------------------------------------------------------+
double ApplyAdaptiveEnhancementM5(BinarySignal &signal, string symbol) {
    double enhancementFactor = 1.0;
    
    // 1. ULTRA AGGRESSIVE M5 PERFORMANCE-BASED ADAPTATION
    if((g_recentWinsM5 + g_recentLossesM5) >= 4) { // React even faster for M5
        double recentWinRate = (double)g_recentWinsM5 / (g_recentWinsM5 + g_recentLossesM5);
        
        if(recentWinRate > 0.75) {
            enhancementFactor *= 1.03; // Very small boost when good
        } else if(recentWinRate < 0.5) {
            enhancementFactor *= 0.3; // MASSIVE penalty when poor
        } else if(recentWinRate < 0.6) {
            enhancementFactor *= 0.5; // Strong penalty when mediocre
        }
    }
    
    // ADDITIONAL: Emergency M5 shutdown if recent performance is terrible
    if((g_recentWinsM5 + g_recentLossesM5) >= 6 && (double)g_recentWinsM5 / (g_recentWinsM5 + g_recentLossesM5) < 0.35) {
        enhancementFactor *= 0.05; // Nearly shut down M5 system
    }
    
    // 2. MARKET VOLATILITY ADAPTATION
    if(signal.volatilityLevel > 1.8) {       // Adjusted for M5
        enhancementFactor *= 0.8; // More conservative in high volatility
    } else if(signal.volatilityLevel < 0.7) {
        enhancementFactor *= 0.9; // Slightly more conservative in low volatility
    }
    
    // 3. TIME-BASED ADAPTATION
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Better performance during overlap sessions
    if((dt.hour >= 13 && dt.hour <= 17) || (dt.hour >= 8 && dt.hour <= 12)) {
        enhancementFactor *= 1.05; // Slight boost during good sessions
    }
    
    // 4. TREND STRENGTH ADAPTATION
    if(signal.trendStrength > 0.8) {         // Adjusted for M5
        enhancementFactor *= 1.1; // Strong trends are more reliable
    } else if(signal.trendStrength < 0.6) {
        enhancementFactor *= 0.8; // Weak trends are less reliable
    }
    
    // 5. CONFIRMATION RATIO ADAPTATION
    int confirmationCount = 0;
    if(signal.m15Confirmed) confirmationCount++;
    if(signal.adxConfirmed) confirmationCount++;
    if(signal.volumeConfirmed) confirmationCount++;
    if(signal.marketStructureConfirmed) confirmationCount++;
    if(signal.volatilityConfirmed) confirmationCount++;
    if(signal.newsTimeConfirmed) confirmationCount++;
    
    double confirmationRatio = (double)confirmationCount / 6.0;
    if(confirmationRatio >= 0.8) {
        enhancementFactor *= 1.15; // High confirmation ratio
    } else if(confirmationRatio < 0.6) {
        enhancementFactor *= 0.75; // Low confirmation ratio
    }
    
    // 6. CONSECUTIVE LOSSES ADAPTATION
    if(g_consecutiveLosses >= 2) {
        enhancementFactor *= (1.0 - (g_consecutiveLosses * 0.1)); // Reduce confidence after losses
    }
    
    // Apply enhancement to signal
    signal.totalScore *= enhancementFactor;
    signal.confidence *= enhancementFactor;
    
    // Update adaptive multiplier
    g_adaptiveMultiplierM5 = enhancementFactor;
    
    return enhancementFactor;
}

//+------------------------------------------------------------------+
//| Update Adaptive Learning System M5                              |
//+------------------------------------------------------------------+
void UpdateAdaptiveLearningM5(bool wasWin) {
    if(wasWin) {
        g_recentWinsM5++;
    } else {
        g_recentLossesM5++;
    }
    
    // Keep only recent history
    if((g_recentWinsM5 + g_recentLossesM5) > g_adaptivePeriodM5) {
        g_recentWinsM5 = (int)(g_recentWinsM5 * 0.9);
        g_recentLossesM5 = (int)(g_recentLossesM5 * 0.9);
    }
    
    // Calculate performance score
    if((g_recentWinsM5 + g_recentLossesM5) > 0) {
        g_performanceScoreM5 = (double)g_recentWinsM5 / (g_recentWinsM5 + g_recentLossesM5);
    }
}

//+------------------------------------------------------------------+
//| Advanced Pattern Recognition System M5                          |
//+------------------------------------------------------------------+
double DetectAdvancedPatternsM5(string symbol, BinarySignal &signal) {
    double patternScore = 0.0;
    
    // Get extended data for pattern analysis
    double closes[20], highs[20], lows[20], opens[20];
    if(CopyClose(symbol, PERIOD_M5, DataIndex, 20, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M5, DataIndex, 20, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M5, DataIndex, 20, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M5, DataIndex, 20, opens) <= 0) {
        return 0.0;
    }
    
    // 1. SUPPORT/RESISTANCE PATTERN
    double currentPrice = closes[0];
    int touchCount = 0;
    double tolerance = (highs[0] - lows[0]) * 2.5; // Adjusted for M5
    
    for(int i = 5; i < 15; i++) {
        if(MathAbs(currentPrice - highs[i]) < tolerance || MathAbs(currentPrice - lows[i]) < tolerance) {
            touchCount++;
        }
    }
    
    if(touchCount >= 2) {
        patternScore += 10.0; // Near support/resistance
    }
    
    // 2. DOUBLE TOP/BOTTOM PATTERN
    for(int i = 2; i < 8; i++) {
        if(highs[0] > highs[1] && highs[i] > highs[i+1] && MathAbs(highs[0] - highs[i]) < tolerance) {
            patternScore -= 15.0; // Double top pattern
            break;
        }
        if(lows[0] < lows[1] && lows[i] < lows[i+1] && MathAbs(lows[0] - lows[i]) < tolerance) {
            patternScore += 15.0; // Double bottom pattern
            break;
        }
    }
    
    // 3. TREND BREAK PATTERN
    bool isUpTrend = true, isDownTrend = true;
    for(int i = 1; i < 5; i++) {
        if(closes[i] <= closes[i+1]) isUpTrend = false;
        if(closes[i] >= closes[i+1]) isDownTrend = false;
    }
    
    if(isUpTrend && closes[0] < closes[1]) {
        patternScore -= 12.0; // Trend break down
    } else if(isDownTrend && closes[0] > closes[1]) {
        patternScore += 12.0; // Trend break up
    }
    
    // 4. ENGULFING PATTERN
    double body0 = MathAbs(closes[0] - opens[0]);
    double body1 = MathAbs(closes[1] - opens[1]);
    
    if(body0 > body1 * 1.5) {
        if(closes[0] > opens[0] && closes[1] < opens[1] && closes[0] > opens[1] && opens[0] < closes[1]) {
            patternScore += 8.0; // Bullish engulfing
        } else if(closes[0] < opens[0] && closes[1] > opens[1] && closes[0] < opens[1] && opens[0] > closes[1]) {
            patternScore -= 8.0; // Bearish engulfing
        }
    }
    
    return patternScore;
}

//+------------------------------------------------------------------+
//| Market Regime Detection System M5                               |
//+------------------------------------------------------------------+
int DetectMarketRegimeM5(string symbol) {
    double closes[50];
    if(CopyClose(symbol, PERIOD_M5, DataIndex, 50, closes) <= 0) {
        return 0; // Unknown
    }
    
    // Calculate trend and volatility characteristics
    double shortMA = 0, longMA = 0;
    for(int i = 0; i < 10; i++) shortMA += closes[i];
    for(int i = 0; i < 30; i++) longMA += closes[i];
    
    shortMA /= 10.0;
    longMA /= 30.0;
    
    // Calculate volatility
    double avgRange = 0;
    for(int i = 0; i < 20; i++) {
        double high = iHigh(symbol, PERIOD_M5, DataIndex + i);
        double low = iLow(symbol, PERIOD_M5, DataIndex + i);
        avgRange += (high - low);
    }
    avgRange /= 20.0;
    
    double currentRange = iHigh(symbol, PERIOD_M5, DataIndex) - iLow(symbol, PERIOD_M5, DataIndex);
    double volatilityRatio = currentRange / avgRange;
    
    // Determine regime (adjusted for M5)
    if(shortMA > longMA * 1.002 && volatilityRatio < 1.8) {  // Adjusted for M5
        return 1; // Stable uptrend
    } else if(shortMA < longMA * 0.998 && volatilityRatio < 1.8) {
        return -1; // Stable downtrend
    } else if(volatilityRatio > 2.5) {                        // Adjusted for M5
        return 2; // High volatility/chaotic
    } else {
        return 0; // Ranging/uncertain
    }
}

//+------------------------------------------------------------------+
//| Get Adaptive Performance Metrics M5                             |
//+------------------------------------------------------------------+
void GetAdaptiveMetricsM5(double &winRate, double &adaptiveMultiplier, int &recentTrades) {
    winRate = g_performanceScoreM5;
    adaptiveMultiplier = g_adaptiveMultiplierM5;
    recentTrades = g_recentWinsM5 + g_recentLossesM5;
}

//+------------------------------------------------------------------+
//| EMERGENCY PERFORMANCE FUNCTIONS M5 TO FIX BAD PERFORMANCE      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check M5 Daily Performance and Activate Emergency Stop          |
//+------------------------------------------------------------------+
void CheckDailyPerformanceM5() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    datetime currentDay = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", dt.year, dt.mon, dt.day));
    
    // Reset daily counters if new day
    if(currentDay != g_lastTradeDayM5) {
        g_dailyTradesM5 = 0;
        g_dailyWinsM5 = 0;
        g_dailyLossesM5 = 0;
        g_dailyWinRateM5 = 0.0;
        g_emergencyStopM5 = false;
        g_lastTradeDayM5 = currentDay;
    }
    
    // Calculate daily win rate
    if(g_dailyTradesM5 > 0) {
        g_dailyWinRateM5 = (double)g_dailyWinsM5 / g_dailyTradesM5;
    }
    
    // EMERGENCY STOP CONDITIONS (stricter for M5)
    if(g_dailyLossesM5 >= g_emergencyStopLossesM5) {
        g_emergencyStopM5 = true;
        Print("🚨 M5 EMERGENCY STOP ACTIVATED - Too many daily losses: ", g_dailyLossesM5);
    }
    
    // Also stop if win rate is terrible after enough trades (stricter for M5)
    if(g_dailyTradesM5 >= 8 && g_dailyWinRateM5 < 0.35) {
        g_emergencyStopM5 = true;
        Print("🚨 M5 EMERGENCY STOP ACTIVATED - Poor daily win rate: ", DoubleToString(g_dailyWinRateM5 * 100, 1), "%");
    }
}

//+------------------------------------------------------------------+
//| Update M5 Daily Performance (Call after each M5 trade)         |
//+------------------------------------------------------------------+
void UpdateDailyPerformanceM5(bool wasWin) {
    g_dailyTradesM5++;
    if(wasWin) {
        g_dailyWinsM5++;
    } else {
        g_dailyLossesM5++;
    }
    
    // Update overall M5 system
    UpdateConsecutiveLossesM5(wasWin);
}

//+------------------------------------------------------------------+
//| Check if it's the BEST M5 Trading Session (ultra strict)       |
//+------------------------------------------------------------------+
bool IsBestTradingSessionM5() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Only trade during PRIME OVERLAP sessions for M5 (even stricter)
    if(dt.day_of_week >= 2 && dt.day_of_week <= 4) { // Tue-Thu only
        // London-NY overlap (13:30-16:30 GMT) - BEST M5 session
        if(dt.hour >= 13 && dt.hour <= 16 && dt.min >= 30) {
            return true;
        }
        // Asian-London overlap (08:00-09:00 GMT) - Good M5 session  
        if(dt.hour >= 8 && dt.hour <= 8) {
            return true;
        }
    }
    
    return false; // Outside prime time = NO M5 TRADING
}

//+------------------------------------------------------------------+
//| ULTRA Enhanced M5 Signal Validation (Super Strict)             |
//+------------------------------------------------------------------+
bool ValidateUltraSignalM5(BinarySignal &signal) {
    // Only allow PERFECT M5 signals
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < 90.0) return false;         // Ultra high bar for M5
    if(signal.riskLevel > 2) return false;             // Only lowest risk M5
    if(signal.totalScore < 110.0) return false;        // Super high M5 score required
    
    // ALL M5 confirmations must be true (no exceptions)
    if(!signal.m15Confirmed) return false;
    if(!signal.adxConfirmed) return false;
    if(!signal.volumeConfirmed) return false;
    if(!signal.marketStructureConfirmed) return false;
    if(!signal.volatilityConfirmed) return false;
    if(!signal.newsTimeConfirmed) return false;
    
    // Additional ULTRA strict M5 checks
    if(signal.trendStrength < 0.75) return false;      // Only strong M5 trends
    if(signal.volatilityLevel > 1.8) return false;     // Avoid high M5 volatility
    
    // Market must be in TRENDING condition for M5
    if(signal.marketCondition != MARKET_TRENDING) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get M5 Emergency Performance Status                             |
//+------------------------------------------------------------------+
void GetEmergencyStatusM5(bool &isEmergencyStop, double &dailyWinRate, int &dailyTrades) {
    isEmergencyStop = g_emergencyStopM5;
    dailyWinRate = g_dailyWinRateM5;
    dailyTrades = g_dailyTradesM5;
}