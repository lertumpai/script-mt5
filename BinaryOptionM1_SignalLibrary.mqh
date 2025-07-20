//+------------------------------------------------------------------+
//| Binary Option M1 Signal Library - ENHANCED VERSION             |
//| Enhanced with advanced filtering to prevent consecutive losses  |
//+------------------------------------------------------------------+
#property copyright "Enhanced Binary M1 Signal Library 2024"
#property version   "2.0"
#property strict

//--- Enhanced Input Parameters
input bool UseAdvancedFilters = true;          // ใช้ฟิลเตอร์ขั้นสูง
input bool UseVolatilityFilter = true;         // ฟิลเตอร์ความผันผวน
input bool UseMarketStructureFilter = true;    // ฟิลเตอร์โครงสร้างตลาด
input bool UseNewsTimeFilter = true;           // หลีกเลี่ยงช่วงข่าว
input double MinTrendStrength = 0.7;           // ความแรงของเทรนด์ขั้นต่ำ
input double MaxVolatilityLevel = 2.0;         // ระดับความผันผวนสูงสุด
input int MaxConsecutiveLosses = 3;            // จำนวนแพ้ติดกันสูงสุด

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
    bool m5Confirmed;                   // M5 timeframe confirmation
    bool volumeConfirmed;               // Volume confirmation
    bool adxConfirmed;                  // ADX strength confirmation
    bool marketStructureConfirmed;      // Market structure confirmation
    bool volatilityConfirmed;           // Volatility confirmation
    bool newsTimeConfirmed;             // News time confirmation
    int riskLevel;                      // Risk level (1-5)
};

//--- Enhanced Signal Parameters Structure
struct SignalParameters {
    // Basic Indicator Settings
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
    
    // Enhanced Thresholds (Stricter)
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

//--- Input Parameters
input int DataIndex = 2; // Bar index for signal calculation (1=live, 2=backtest recommended)

//--- Enhanced Global Variables for Indicators
int g_emaFast_handle = INVALID_HANDLE;
int g_emaSlow_handle = INVALID_HANDLE;
int g_emaFastM5_handle = INVALID_HANDLE;
int g_emaSlowM5_handle = INVALID_HANDLE;
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
bool InitializeBinarySignalSystem(string symbol = "") {
    return InitializeBinarySignalSystem(symbol, false, g_params);
}

//+------------------------------------------------------------------+
//| Initialize Signal System                                         |
//+------------------------------------------------------------------+
bool InitializeBinarySignalSystem(string symbol, bool useCustomParams, SignalParameters &customParams) {
    // Use current symbol if not specified
    if(symbol == "") symbol = Symbol();
    
    // Set default parameters if not provided
    if(!useCustomParams) {
        SetDefaultParameters();
    } else {
        g_params = customParams;
    }
    
    // Initialize M1 indicators
    g_emaFast_handle = iMA(symbol, PERIOD_M1, g_params.emaFast, 0, MODE_EMA, PRICE_CLOSE);
    g_emaSlow_handle = iMA(symbol, PERIOD_M1, g_params.emaSlow, 0, MODE_EMA, PRICE_CLOSE);
    g_rsi_handle = iRSI(symbol, PERIOD_M1, g_params.rsiPeriod, PRICE_CLOSE);
    g_macd_handle = iMACD(symbol, PERIOD_M1, g_params.macdFast, g_params.macdSlow, g_params.macdSignal, PRICE_CLOSE);
    g_stoch_handle = iStochastic(symbol, PERIOD_M1, g_params.stochK, g_params.stochD, g_params.stochSlowing, MODE_SMA, STO_LOWHIGH);
    g_bb_handle = iBands(symbol, PERIOD_M1, g_params.bbPeriod, g_params.bbDeviation, 0, PRICE_CLOSE);
    g_adx_handle = iADX(symbol, PERIOD_M1, g_params.adxPeriod);
    g_atr_handle = iATR(symbol, PERIOD_M1, g_params.atrPeriod);
    
    // Initialize M5 trend confirmation indicators
    if(g_params.useMultiTimeframe) {
        g_emaFastM5_handle = iMA(symbol, PERIOD_M5, g_params.emaFast, 0, MODE_EMA, PRICE_CLOSE);
        g_emaSlowM5_handle = iMA(symbol, PERIOD_M5, g_params.emaSlow, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    // Verify all handles
    if(g_emaFast_handle == INVALID_HANDLE || g_emaSlow_handle == INVALID_HANDLE ||
       g_rsi_handle == INVALID_HANDLE || g_macd_handle == INVALID_HANDLE ||
       g_stoch_handle == INVALID_HANDLE || g_bb_handle == INVALID_HANDLE ||
       g_adx_handle == INVALID_HANDLE || g_atr_handle == INVALID_HANDLE) {
        Print("ERROR: Failed to initialize enhanced M1 indicators");
        return false;
    }
    
    if(g_params.useMultiTimeframe) {
        if(g_emaFastM5_handle == INVALID_HANDLE || g_emaSlowM5_handle == INVALID_HANDLE) {
            Print("ERROR: Failed to initialize M5 indicators");
            return false;
        }
    }
    
    g_initialized = true;
    Print("✅ Binary Signal System initialized successfully for ", symbol);
    return true;
}

//+------------------------------------------------------------------+
//| Set Enhanced Default Parameters                                  |
//+------------------------------------------------------------------+
void SetDefaultParameters() {
    // Basic indicators (more conservative)
    g_params.emaFast = 21;
    g_params.emaSlow = 55;
    g_params.rsiPeriod = 14;
    g_params.macdFast = 12;
    g_params.macdSlow = 26;
    g_params.macdSignal = 9;
    g_params.stochK = 14;
    g_params.stochD = 3;
    g_params.stochSlowing = 3;
    g_params.bbPeriod = 20;
    g_params.bbDeviation = 2.0;
    g_params.adxPeriod = 14;
    g_params.volumeMAPeriod = 20;
    
    // Enhanced thresholds (stricter to prevent losses)
    g_params.minConfidence = 80.0;              // Increased from 70
    g_params.strongSignalThreshold = 80.0;      // Increased from 70
    g_params.moderateSignalThreshold = 70.0;    // Increased from 60
    g_params.weakSignalThreshold = 60.0;        // Increased from 50
    
    // ADX filters (stricter)
    g_params.useADXFilter = true;
    g_params.minADXLevel = 25.0;
    g_params.maxADXLevel = 80.0;                // Avoid over-trending
    
    // Volatility settings
    g_params.atrPeriod = 14;
    g_params.minATR = 0.0001;                   // Minimum volatility required
    g_params.maxATR = 0.0050;                   // Maximum volatility allowed
    
    // Market structure
    g_params.swingPeriod = 10;
    g_params.minSwingSize = 10.0;               // Points
    
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
BinarySignal GetBinarySignal(string symbol = "") {
    BinarySignal signal;
    
    // Initialize enhanced signal structure
    ZeroMemory(signal);
    signal.direction = SIGNAL_NONE;
    signal.strength = STRENGTH_WEAK;
    signal.confidence = 0.0;
    signal.totalScore = 0.0;
    signal.trendScore = 0.0;
    signal.momentumScore = 0.0;
    signal.oscillatorScore = 0.0;
    signal.volumeScore = 0.0;
    signal.trendStrength = 0.0;
    signal.volatilityLevel = 0.0;
    signal.marketCondition = MARKET_UNKNOWN;
    signal.reason = "No Signal";
    signal.timestamp = TimeCurrent();
    signal.isValid = false;
    signal.m5Confirmed = false;
    signal.volumeConfirmed = false;
    signal.adxConfirmed = false;
    signal.marketStructureConfirmed = false;
    signal.volatilityConfirmed = false;
    signal.newsTimeConfirmed = false;
    signal.riskLevel = 1;
    
    // Use current symbol if not specified
    if(symbol == "") symbol = Symbol();
    
    // Check if system is initialized
    if(!g_initialized) {
        if(!InitializeBinarySignalSystem(symbol)) {
            signal.reason = "System not initialized";
            return signal;
        }
    }
    
    // Set entry price
    signal.entryPrice = (SymbolInfoDouble(symbol, SYMBOL_ASK) + SymbolInfoDouble(symbol, SYMBOL_BID)) / 2.0;
    
    // ENHANCED: Analyze market condition first
    AnalyzeMarketCondition(symbol, signal);
    
    // ENHANCED: Pre-filters - Check if we should trade at all
    if(!PassPreFilters(signal)) {
        signal.reason = "Failed pre-filters";
        return signal;
    }
    
    // Calculate individual component scores
    signal.trendScore = CalculateTrendScore(symbol);
    signal.momentumScore = CalculateMomentumScore(symbol);
    signal.oscillatorScore = CalculateOscillatorScore(symbol);
    signal.volumeScore = CalculateVolumeScore(symbol);
    
    // ENHANCED: Calculate total score with weighted components (trend most important)
    signal.totalScore = (signal.trendScore * 0.4) + 
                       (signal.momentumScore * 0.3) + 
                       (signal.oscillatorScore * 0.2) + 
                       (signal.volumeScore * 0.1);
    signal.confidence = MathAbs(signal.totalScore);
    
    // ENHANCED: Apply all confirmations
    ApplyEnhancedConfirmations(signal, symbol);
    
    // ULTIMATE: Apply advanced pattern recognition
    double patternScore = DetectAdvancedPatterns(symbol, signal);
    signal.totalScore += patternScore * 0.15; // Add 15% weight to pattern analysis
    
    // ULTIMATE: Apply adaptive enhancement (machine learning-like)
    double adaptiveFactor = ApplyAdaptiveEnhancement(signal, symbol);
    
    // Determine signal direction and strength
    DetermineSignalDirectionAndStrength(signal);
    
    // ENHANCED: Validate signal with stricter criteria
    signal.isValid = ValidateEnhancedSignal(signal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| ENHANCED Calculate Trend Score (Advanced Logic)                 |
//+------------------------------------------------------------------+
double CalculateTrendScore(string symbol) {
    double emaFast[], emaSlow[], closes[], highs[], lows[];
    
    if(CopyBuffer(g_emaFast_handle, 0, DataIndex, 5, emaFast) <= 0 ||
       CopyBuffer(g_emaSlow_handle, 0, DataIndex, 5, emaSlow) <= 0 ||
       CopyClose(symbol, PERIOD_M1, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M1, DataIndex, 3, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, 3, lows) <= 0) {
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
    
    // 3. EMA Distance and Strength (±15 points)
    double distance = MathAbs(emaFast[0] - emaSlow[0]) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    double normalizedDistance = MathMin(distance / 50.0, 1.0); // More sensitive
    
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
//| ENHANCED Calculate Momentum Score (Advanced Analysis)           |
//+------------------------------------------------------------------+
double CalculateMomentumScore(string symbol) {
    double rsi[], macdMain[], macdSignal[], closes[], highs[], lows[];
    
    if(CopyBuffer(g_rsi_handle, 0, DataIndex, 5, rsi) <= 0 ||
       CopyBuffer(g_macd_handle, 0, DataIndex, 5, macdMain) <= 0 ||
       CopyBuffer(g_macd_handle, 1, DataIndex, 5, macdSignal) <= 0 ||
       CopyClose(symbol, PERIOD_M1, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M1, DataIndex, 5, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, 5, lows) <= 0) {
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
//| Calculate Oscillator Score                                       |
//+------------------------------------------------------------------+
//| ENHANCED Calculate Oscillator Score (Advanced Pattern Analysis) |
//+------------------------------------------------------------------+
double CalculateOscillatorScore(string symbol) {
    double stochK[], stochD[], bbUpper[], bbMiddle[], bbLower[];
    double closes[], highs[], lows[], opens[];
    
    if(CopyBuffer(g_stoch_handle, 0, DataIndex, 5, stochK) <= 0 ||
       CopyBuffer(g_stoch_handle, 1, DataIndex, 5, stochD) <= 0 ||
       CopyBuffer(g_bb_handle, 0, DataIndex, 10, bbUpper) <= 0 ||
       CopyBuffer(g_bb_handle, 1, DataIndex, 10, bbMiddle) <= 0 ||
       CopyBuffer(g_bb_handle, 2, DataIndex, 10, bbLower) <= 0 ||
       CopyClose(symbol, PERIOD_M1, DataIndex, 5, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M1, DataIndex, 5, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, 5, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M1, DataIndex, 5, opens) <= 0) {
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
//| ENHANCED Calculate Volume Score (Advanced VPA Analysis)         |
//+------------------------------------------------------------------+
double CalculateVolumeScore(string symbol) {
    if(!g_params.useVolumeFilter) return 0.0;
    
    // Collect volume and price data
    long volumes[10];
    double closes[10], highs[10], lows[10], opens[10];
    
    bool dataValid = true;
    for(int i = 0; i < 10; i++) {
        volumes[i] = iVolume(symbol, PERIOD_M1, DataIndex + i);
        if(volumes[i] <= 0) dataValid = false;
    }
    
    if(!dataValid || 
       CopyClose(symbol, PERIOD_M1, DataIndex, 10, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M1, DataIndex, 10, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, 10, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M1, DataIndex, 10, opens) <= 0) {
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
    if(currentVolume > avgVolume * 2.0) {
        score += 15.0; // Extremely high volume
    } else if(currentVolume > avgVolume * 1.5) {
        score += 12.0; // Very high volume
    } else if(currentVolume > avgVolume * 1.2) {
        score += 8.0;  // High volume
    } else if(currentVolume > avgVolume * 0.8) {
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
    if(MathAbs(priceChangePercent) > 0.05) { // Significant price movement
        if(currentVolume > avgVolume * 1.3) {
            if(priceChange > 0) {
                score += 20.0; // High volume bullish move
            } else {
                score -= 20.0; // High volume bearish move
            }
        } else if(currentVolume < avgVolume * 0.7) {
            if(priceChange > 0) {
                score -= 10.0; // Low volume bullish move (weak)
            } else {
                score += 10.0; // Low volume bearish move (weak)
            }
        }
    }
    
    // Price close position within range
    double closePosition = (priceRange > 0) ? (currentClose - lows[0]) / priceRange : 0.5;
    if(currentVolume > avgVolume * 1.2) {
        if(closePosition > 0.7) {
            score += 10.0; // High volume with close near high
        } else if(closePosition < 0.3) {
            score -= 10.0; // High volume with close near low
        }
    }
    
    // 3. VOLUME MOMENTUM ANALYSIS (±15 points)
    double volumeMomentum = (double)currentVolume - (double)prevVolume;
    double volumeChangePercent = (prevVolume > 0) ? (volumeMomentum / prevVolume) * 100 : 0;
    
    if(volumeChangePercent > 50) {
        if(currentClose > prevClose) {
            score += 15.0; // Increasing volume with price up
        } else {
            score -= 12.0; // Increasing volume with price down
        }
    } else if(volumeChangePercent > 20) {
        if(currentClose > prevClose) {
            score += 8.0; // Moderate volume increase with price up
        } else {
            score -= 6.0; // Moderate volume increase with price down
        }
    } else if(volumeChangePercent < -30) {
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
    if(currentVolume > maxVolume && currentVolume > avgVolume * 2.0) {
        // Volume spike - very significant
        if(MathAbs(priceChangePercent) > 0.1) {
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
//| Check M5 Trend Alignment                                         |
//+------------------------------------------------------------------+
bool CheckM5TrendAlignment(double m1Signal, string symbol) {
    if(!g_params.useMultiTimeframe) return true;
    
    double emaFastM5[], emaSlowM5[];
    
    // For M5 confirmation, use index based on M1 to M5 ratio (approximately 1/5)
    int m5Index = (DataIndex > 1) ? (DataIndex / 5) + 1 : 1;
    
    if(CopyBuffer(g_emaFastM5_handle, 0, m5Index, 1, emaFastM5) <= 0 ||
       CopyBuffer(g_emaSlowM5_handle, 0, m5Index, 1, emaSlowM5) <= 0) {
        return false;
    }
    
    bool m5Bullish = (emaFastM5[0] > emaSlowM5[0]);
    bool m5Bearish = (emaFastM5[0] < emaSlowM5[0]);
    
    if(m1Signal > 0 && m5Bullish) return true;
    if(m1Signal < 0 && m5Bearish) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check ADX Strength                                               |
//+------------------------------------------------------------------+
bool CheckADXStrength(string symbol) {
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
bool CheckVolumeConfirmation(string symbol) {
    if(!g_params.useVolumeFilter) return true;
    
    // Get current volume
    long currentVolume = iVolume(symbol, PERIOD_M1, DataIndex);
    
    // Calculate average volume from recent 10 bars
    long totalVolume = 0;
    int validBars = 0;
    
    for(int i = DataIndex; i <= DataIndex + 9; i++) {
        long barVolume = iVolume(symbol, PERIOD_M1, i);
        if(barVolume > 0) {
            totalVolume += barVolume;
            validBars++;
        }
    }
    
    if(validBars == 0) return false;
    
    double avgVolume = (double)totalVolume / validBars;
    
    return (currentVolume > avgVolume * 1.1);
}

//+------------------------------------------------------------------+
//| Determine Signal Direction and Strength                          |
//+------------------------------------------------------------------+
void DetermineSignalDirectionAndStrength(BinarySignal &signal) {
    double totalScore = signal.totalScore;
    
    // Count confirmations for enhanced validation
    int confirmations = 0;
    if(signal.m5Confirmed) confirmations++;
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
        signal.reason = StringFormat("STRONG %s - Score: %.1f, Confirmations: %d/6", 
                                   (totalScore > 0) ? "CALL" : "PUT", totalScore, confirmations);
    }
    else if(MathAbs(totalScore) >= g_params.moderateSignalThreshold && confirmations >= (requiredConfirmations - 1)) {
        signal.direction = (totalScore > 0) ? SIGNAL_CALL : SIGNAL_PUT;
        signal.strength = STRENGTH_MODERATE;
        signal.reason = StringFormat("MODERATE %s - Score: %.1f, Confirmations: %d/6", 
                                   (totalScore > 0) ? "CALL" : "PUT", totalScore, confirmations);
    }
    else {
        signal.direction = SIGNAL_NONE;
        signal.strength = STRENGTH_WEAK;
        signal.reason = StringFormat("NO SIGNAL - Score: %.1f, Confirmations: %d/6 (Need %d+)", 
                                   totalScore, confirmations, requiredConfirmations);
    }
}

//+------------------------------------------------------------------+
//| Validate Signal                                                  |
//+------------------------------------------------------------------+
bool ValidateSignal(BinarySignal &signal) {
    // Basic validation
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < g_params.minConfidence) return false;
    
    // Confirmation requirements
    if(g_params.useMultiTimeframe && !signal.m5Confirmed) return false;
    if(g_params.useADXFilter && !signal.adxConfirmed) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get Signal Strength as String                                   |
//+------------------------------------------------------------------+
string SignalStrengthToString(SIGNAL_STRENGTH strength) {
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
string SignalDirectionToString(SIGNAL_DIRECTION direction) {
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
void PrintSignalInfo(BinarySignal &signal) {
    Print("=== BINARY SIGNAL INFO ===");
    Print("Direction: ", SignalDirectionToString(signal.direction));
    Print("Strength: ", SignalStrengthToString(signal.strength));
    Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
    Print("Total Score: ", DoubleToString(signal.totalScore, 1));
    Print("Components: T:", DoubleToString(signal.trendScore, 1), 
          " M:", DoubleToString(signal.momentumScore, 1),
          " O:", DoubleToString(signal.oscillatorScore, 1),
          " V:", DoubleToString(signal.volumeScore, 1));
    Print("Confirmations: M5:", signal.m5Confirmed, " ADX:", signal.adxConfirmed, " Vol:", signal.volumeConfirmed);
    Print("Valid: ", signal.isValid);
    Print("Reason: ", signal.reason);
    Print("Timestamp: ", TimeToString(signal.timestamp, TIME_DATE|TIME_SECONDS));
    Print("Entry Price: ", DoubleToString(signal.entryPrice, 5));
    Print("========================");
}

//+------------------------------------------------------------------+
//| Update Signal Parameters                                         |
//+------------------------------------------------------------------+
void UpdateSignalParameters(const SignalParameters &newParams) {
    g_params = newParams;
    g_initialized = false; // Force re-initialization with new parameters
}

//+------------------------------------------------------------------+
//| Get Current Signal Parameters                                    |
//+------------------------------------------------------------------+
SignalParameters GetSignalParameters() {
    return g_params;
}

//+------------------------------------------------------------------+
//| Cleanup Function                                                 |
//+------------------------------------------------------------------+
void CleanupBinarySignalSystem() {
    if(g_emaFast_handle != INVALID_HANDLE) IndicatorRelease(g_emaFast_handle);
    if(g_emaSlow_handle != INVALID_HANDLE) IndicatorRelease(g_emaSlow_handle);
    if(g_emaFastM5_handle != INVALID_HANDLE) IndicatorRelease(g_emaFastM5_handle);
    if(g_emaSlowM5_handle != INVALID_HANDLE) IndicatorRelease(g_emaSlowM5_handle);
    if(g_rsi_handle != INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
    if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
    if(g_stoch_handle != INVALID_HANDLE) IndicatorRelease(g_stoch_handle);
    if(g_bb_handle != INVALID_HANDLE) IndicatorRelease(g_bb_handle);
    if(g_adx_handle != INVALID_HANDLE) IndicatorRelease(g_adx_handle);
    if(g_atr_handle != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
    
    g_initialized = false;
    Print("Enhanced Binary Signal System cleaned up");
}

//+------------------------------------------------------------------+
//| Quick Signal Check (Simple version)                             |
//+------------------------------------------------------------------+
int GetQuickSignal(string symbol = "", double minConfidence = 70.0) {
    BinarySignal signal = GetBinarySignal(symbol);
    
    if(signal.isValid && signal.confidence >= minConfidence) {
        return (int)signal.direction;
    }
    
    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Check if Signal System is Ready                                 |
//+------------------------------------------------------------------+
bool IsSignalSystemReady() {
    return g_initialized;
}

//+------------------------------------------------------------------+
//| ENHANCED FUNCTIONS TO PREVENT CONSECUTIVE LOSSES                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Analyze Market Condition                                         |
//+------------------------------------------------------------------+
void AnalyzeMarketCondition(string symbol, BinarySignal &signal) {
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
        if(adx[0] > 40) {
            g_marketCondition = MARKET_TRENDING;
        } else if(adx[0] < 20) {
            g_marketCondition = MARKET_RANGING;
        } else {
            g_marketCondition = MARKET_UNKNOWN;
        }
        
        // Override if volatility too high
        if(signal.volatilityLevel > 2.0) {
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
//| Pre-Filters Check (CRITICAL FOR PREVENTING LOSSES)             |
//+------------------------------------------------------------------+
bool PassPreFilters(BinarySignal &signal) {
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
    if(UseNewsTimeFilter && IsNewsTime()) {
        signal.reason = "News time - avoiding trade";
        return false;
    }
    
    // 5. Session filter
    if(g_params.useSessionFilter && !IsGoodTradingSession()) {
        signal.reason = "Poor trading session";
        return false;
    }
    
    // 6. Consecutive losses filter
    if(g_consecutiveLosses >= g_params.maxConsecutiveLosses) {
        signal.reason = StringFormat("Max consecutive losses reached (%d)", g_consecutiveLosses);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply Enhanced Confirmations                                     |
//+------------------------------------------------------------------+
void ApplyEnhancedConfirmations(BinarySignal &signal, string symbol) {
    // 1. M5 confirmation (enhanced)
    signal.m5Confirmed = CheckEnhancedM5TrendAlignment(signal.totalScore, symbol);
    
    // 2. ADX confirmation with range check
    double adx[];
    if(CopyBuffer(g_adx_handle, 0, DataIndex, 1, adx) > 0) {
        signal.adxConfirmed = (adx[0] >= g_params.minADXLevel && adx[0] <= g_params.maxADXLevel);
    }
    
    // 3. Volume confirmation
    signal.volumeConfirmed = CheckVolumeConfirmation(symbol);
    
    // 4. Market structure confirmation
    signal.marketStructureConfirmed = CheckMarketStructure(symbol);
    
    // 5. Volatility confirmation
    signal.volatilityConfirmed = (signal.volatilityLevel >= 0.5 && signal.volatilityLevel <= MaxVolatilityLevel);
    
    // 6. News time confirmation
    signal.newsTimeConfirmed = !IsNewsTime();
    
    // Calculate risk level
    signal.riskLevel = CalculateRiskLevel(signal);
}

//+------------------------------------------------------------------+
//| Enhanced M5 Trend Alignment Check                               |
//+------------------------------------------------------------------+
bool CheckEnhancedM5TrendAlignment(double m1Signal, string symbol) {
    if(!g_params.useMultiTimeframe) return true;
    
    double emaFastM5[], emaSlowM5[];
    int m5Index = (DataIndex > 1) ? (DataIndex / 5) + 1 : 1;
    
    if(CopyBuffer(g_emaFastM5_handle, 0, m5Index, 3, emaFastM5) <= 0 ||
       CopyBuffer(g_emaSlowM5_handle, 0, m5Index, 3, emaSlowM5) <= 0) {
        return false;
    }
    
    // Check M5 trend direction
    bool m5Bullish = (emaFastM5[0] > emaSlowM5[0]);
    bool m5Bearish = (emaFastM5[0] < emaSlowM5[0]);
    
    // Check M5 trend consistency (more strict)
    bool m5TrendUp = (emaFastM5[0] > emaFastM5[1] && emaFastM5[1] > emaFastM5[2]);
    bool m5TrendDown = (emaFastM5[0] < emaFastM5[1] && emaFastM5[1] < emaFastM5[2]);
    
    if(m1Signal > 0) {
        return (m5Bullish && (m5TrendUp || emaFastM5[0] > emaFastM5[1]));
    } else if(m1Signal < 0) {
        return (m5Bearish && (m5TrendDown || emaFastM5[0] < emaFastM5[1]));
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Market Structure                                            |
//+------------------------------------------------------------------+
bool CheckMarketStructure(string symbol) {
    if(!UseMarketStructureFilter) return true;
    
    // Check for clear swing highs and lows
    double highs[], lows[];
    int period = g_params.swingPeriod;
    
    if(CopyHigh(symbol, PERIOD_M1, DataIndex, period, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, period, lows) <= 0) {
        return false;
    }
    
    // Find recent swing points
    double maxHigh = highs[ArrayMaximum(highs)];
    double minLow = lows[ArrayMinimum(lows)];
    double swingSize = (maxHigh - minLow) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    return (swingSize >= g_params.minSwingSize);
}

//+------------------------------------------------------------------+
//| Check if it's News Time                                          |
//+------------------------------------------------------------------+
bool IsNewsTime() {
    if(!UseNewsTimeFilter) return false;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Avoid major news times (GMT)
    // Simple implementation: avoid 13:00-14:00 GMT and 19:00-20:00 GMT on weekdays
    if(dt.day_of_week >= 1 && dt.day_of_week <= 5) {
        if((dt.hour >= 13 && dt.hour < 14) || (dt.hour >= 19 && dt.hour < 20)) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if Good Trading Session                                    |
//+------------------------------------------------------------------+
bool IsGoodTradingSession() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // GMT hours for major sessions
    // London: 8:00-17:00, New York: 13:00-22:00, Overlap: 13:00-17:00 (Best)
    if(dt.day_of_week >= 1 && dt.day_of_week <= 5) {
        if((dt.hour >= 8 && dt.hour <= 17) || (dt.hour >= 13 && dt.hour <= 22)) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Risk Level                                             |
//+------------------------------------------------------------------+
int CalculateRiskLevel(BinarySignal &signal) {
    int risk = 1; // Start with low risk
    
    // Increase risk based on various factors
    if(!signal.m5Confirmed) risk++;
    if(!signal.adxConfirmed) risk++;
    if(!signal.volumeConfirmed) risk++;
    if(!signal.marketStructureConfirmed) risk++;
    if(!signal.volatilityConfirmed) risk++;
    if(signal.marketCondition == MARKET_VOLATILE) risk += 2;
    if(signal.trendStrength < 0.7) risk++;
    
    return MathMin(risk, 5); // Cap at 5
}

//+------------------------------------------------------------------+
//| Enhanced Signal Validation (STRICTER CRITERIA)                  |
//+------------------------------------------------------------------+
bool ValidateEnhancedSignal(BinarySignal &signal) {
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < g_params.minConfidence) return false;
    if(signal.riskLevel > 3) return false; // Reject high-risk signals
    
    // Count confirmations
    int confirmations = 0;
    if(signal.m5Confirmed) confirmations++;
    if(signal.adxConfirmed) confirmations++;
    if(signal.volumeConfirmed) confirmations++;
    if(signal.marketStructureConfirmed) confirmations++;
    if(signal.volatilityConfirmed) confirmations++;
    if(signal.newsTimeConfirmed) confirmations++;
    
    // Require minimum 4/6 confirmations
    if(confirmations < 4) return false;
    
    // Additional mandatory validations
    if(!signal.m5Confirmed) return false;
    if(!signal.adxConfirmed) return false;
    if(!signal.newsTimeConfirmed) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Track Consecutive Losses (CALL THIS AFTER EACH TRADE)          |
//+------------------------------------------------------------------+
void UpdateConsecutiveLosses(bool wasWin) {
    if(wasWin) {
        g_consecutiveLosses = 0;
    } else {
        g_consecutiveLosses++;
    }
    
    // ULTIMATE: Update adaptive learning system
    UpdateAdaptiveLearning(wasWin);
}

//+------------------------------------------------------------------+
//| Get Current Consecutive Losses Count                             |
//+------------------------------------------------------------------+
int GetConsecutiveLossesCount() {
    return g_consecutiveLosses;
}

//+------------------------------------------------------------------+
//| Print Enhanced Signal Information                                |
//+------------------------------------------------------------------+
void PrintEnhancedSignalInfo(BinarySignal &signal) {
    Print("=== ULTIMATE ENHANCED M1 SIGNAL ===");
    Print("Direction: ", EnumToStringSignalDirection(signal.direction));
    Print("Confidence: ", DoubleToString(signal.confidence, 1), "%");
    Print("Total Score: ", DoubleToString(signal.totalScore, 1));
    Print("Risk Level: ", signal.riskLevel, "/5");
    Print("Trend Strength: ", DoubleToString(signal.trendStrength, 2));
    Print("Volatility Level: ", DoubleToString(signal.volatilityLevel, 2));
    Print("Confirmations: M5:", signal.m5Confirmed, " ADX:", signal.adxConfirmed, 
          " Vol:", signal.volumeConfirmed, " Struct:", signal.marketStructureConfirmed);
    Print("Filters: Volatility:", signal.volatilityConfirmed, " News:", signal.newsTimeConfirmed);
    Print("Valid: ", signal.isValid);
    Print("Reason: ", signal.reason);
    Print("Consecutive Losses: ", g_consecutiveLosses);
    
    // ULTIMATE: Show adaptive intelligence metrics
    Print("--- ADAPTIVE INTELLIGENCE ---");
    Print("Adaptive Multiplier: ", DoubleToString(g_adaptiveMultiplier, 3));
    Print("Recent Win Rate: ", DoubleToString(g_performanceScore * 100, 1), "%");
    Print("Recent Trades: ", (g_recentWins + g_recentLosses));
    Print("Market Condition: ", signal.marketCondition);
    Print("================================");
}

//+------------------------------------------------------------------+
//| ULTIMATE ENHANCEMENT: Adaptive Signal Intelligence              |
//+------------------------------------------------------------------+

// Global adaptive learning variables
double g_adaptiveMultiplier = 1.0;
int g_recentWins = 0;
int g_recentLosses = 0;
int g_adaptivePeriod = 20;
double g_performanceScore = 0.0;

//+------------------------------------------------------------------+
//| Adaptive Signal Enhancement (Machine Learning-like)             |
//+------------------------------------------------------------------+
double ApplyAdaptiveEnhancement(BinarySignal &signal, string symbol) {
    double enhancementFactor = 1.0;
    
    // 1. PERFORMANCE-BASED ADAPTATION
    if((g_recentWins + g_recentLosses) >= 10) {
        double recentWinRate = (double)g_recentWins / (g_recentWins + g_recentLosses);
        
        if(recentWinRate > 0.8) {
            enhancementFactor *= 1.1; // Increase confidence when performing well
        } else if(recentWinRate < 0.4) {
            enhancementFactor *= 0.7; // Decrease confidence when performing poorly
        }
    }
    
    // 2. MARKET VOLATILITY ADAPTATION
    if(signal.volatilityLevel > 1.5) {
        enhancementFactor *= 0.8; // More conservative in high volatility
    } else if(signal.volatilityLevel < 0.8) {
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
    if(signal.trendStrength > 0.85) {
        enhancementFactor *= 1.1; // Strong trends are more reliable
    } else if(signal.trendStrength < 0.6) {
        enhancementFactor *= 0.8; // Weak trends are less reliable
    }
    
    // 5. CONFIRMATION RATIO ADAPTATION
    int confirmationCount = 0;
    if(signal.m5Confirmed) confirmationCount++;
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
    g_adaptiveMultiplier = enhancementFactor;
    
    return enhancementFactor;
}

//+------------------------------------------------------------------+
//| Update Adaptive Learning System                                  |
//+------------------------------------------------------------------+
void UpdateAdaptiveLearning(bool wasWin) {
    if(wasWin) {
        g_recentWins++;
    } else {
        g_recentLosses++;
    }
    
    // Keep only recent history
    if((g_recentWins + g_recentLosses) > g_adaptivePeriod) {
        g_recentWins = (int)(g_recentWins * 0.9);
        g_recentLosses = (int)(g_recentLosses * 0.9);
    }
    
    // Calculate performance score
    if((g_recentWins + g_recentLosses) > 0) {
        g_performanceScore = (double)g_recentWins / (g_recentWins + g_recentLosses);
    }
}

//+------------------------------------------------------------------+
//| Advanced Pattern Recognition System                              |
//+------------------------------------------------------------------+
double DetectAdvancedPatterns(string symbol, BinarySignal &signal) {
    double patternScore = 0.0;
    
    // Get extended data for pattern analysis
    double closes[20], highs[20], lows[20], opens[20];
    if(CopyClose(symbol, PERIOD_M1, DataIndex, 20, closes) <= 0 ||
       CopyHigh(symbol, PERIOD_M1, DataIndex, 20, highs) <= 0 ||
       CopyLow(symbol, PERIOD_M1, DataIndex, 20, lows) <= 0 ||
       CopyOpen(symbol, PERIOD_M1, DataIndex, 20, opens) <= 0) {
        return 0.0;
    }
    
    // 1. SUPPORT/RESISTANCE PATTERN
    double currentPrice = closes[0];
    int touchCount = 0;
    double tolerance = (highs[0] - lows[0]) * 2.0; // 2x current range tolerance
    
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
//| Market Regime Detection System                                   |
//+------------------------------------------------------------------+
int DetectMarketRegime(string symbol) {
    double closes[50];
    if(CopyClose(symbol, PERIOD_M1, DataIndex, 50, closes) <= 0) {
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
        double high = iHigh(symbol, PERIOD_M1, DataIndex + i);
        double low = iLow(symbol, PERIOD_M1, DataIndex + i);
        avgRange += (high - low);
    }
    avgRange /= 20.0;
    
    double currentRange = iHigh(symbol, PERIOD_M1, DataIndex) - iLow(symbol, PERIOD_M1, DataIndex);
    double volatilityRatio = currentRange / avgRange;
    
    // Determine regime
    if(shortMA > longMA * 1.001 && volatilityRatio < 1.5) {
        return 1; // Stable uptrend
    } else if(shortMA < longMA * 0.999 && volatilityRatio < 1.5) {
        return -1; // Stable downtrend
    } else if(volatilityRatio > 2.0) {
        return 2; // High volatility/chaotic
    } else {
        return 0; // Ranging/uncertain
    }
}

//+------------------------------------------------------------------+
//| Get Adaptive Performance Metrics                                 |
//+------------------------------------------------------------------+
void GetAdaptiveMetrics(double &winRate, double &adaptiveMultiplier, int &recentTrades) {
    winRate = g_performanceScore;
    adaptiveMultiplier = g_adaptiveMultiplier;
    recentTrades = g_recentWins + g_recentLosses;
} 