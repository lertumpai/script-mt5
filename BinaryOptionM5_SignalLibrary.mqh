//+------------------------------------------------------------------+
//| Binary Option M5 Signal Library                                 |
//| Function-based signal generation for M5 timeframe              |
//+------------------------------------------------------------------+
#property copyright "Binary M5 Signal Library 2024"
#property version   "1.0"
#property strict

//--- Input Parameters
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

//--- Signal Structure
struct BinarySignal {
    SIGNAL_DIRECTION direction;     // Signal direction
    SIGNAL_STRENGTH strength;       // Signal strength
    double confidence;              // Confidence level (0-100)
    double totalScore;              // Combined score
    double trendScore;              // Trend component score
    double momentumScore;           // Momentum component score
    double oscillatorScore;         // Oscillator component score
    double volumeScore;             // Volume component score
    string reason;                  // Signal reason
    datetime timestamp;             // Signal timestamp
    double entryPrice;              // Entry price
    bool isValid;                   // Signal validity
    bool m15Confirmed;              // M15 timeframe confirmation
    bool volumeConfirmed;           // Volume confirmation
    bool adxConfirmed;              // ADX strength confirmation
};

//--- Signal Parameters Structure
struct SignalParameters {
    // EMA Settings (adjusted for M5)
    int emaFast;
    int emaSlow;
    
    // RSI Settings
    int rsiPeriod;
    
    // MACD Settings
    int macdFast;
    int macdSlow;
    int macdSignal;
    
    // Stochastic Settings
    int stochK;
    int stochD;
    int stochSlowing;
    
    // Bollinger Bands Settings
    int bbPeriod;
    double bbDeviation;
    
    // ADX Settings
    int adxPeriod;
    
    // Volume Settings
    int volumeMAPeriod;
    
    // Signal Thresholds
    double minConfidence;
    double strongSignalThreshold;
    double moderateSignalThreshold;
    double weakSignalThreshold;
    
    // Filters
    bool useMultiTimeframe;
    bool useVolumeFilter;
    bool useADXFilter;
    double minADXLevel;
};

//--- Global Variables for Indicators
int g_emaFast_handle = INVALID_HANDLE;
int g_emaSlow_handle = INVALID_HANDLE;
int g_emaFastM15_handle = INVALID_HANDLE;
int g_emaSlowM15_handle = INVALID_HANDLE;
int g_rsi_handle = INVALID_HANDLE;
int g_macd_handle = INVALID_HANDLE;
int g_stoch_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;
int g_adx_handle = INVALID_HANDLE;

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
    
    // Initialize M15 trend confirmation indicators
    if(g_params.useMultiTimeframe) {
        g_emaFastM15_handle = iMA(symbol, PERIOD_M15, g_params.emaFast, 0, MODE_EMA, PRICE_CLOSE);
        g_emaSlowM15_handle = iMA(symbol, PERIOD_M15, g_params.emaSlow, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    // Verify all handles
    if(g_emaFast_handle == INVALID_HANDLE || g_emaSlow_handle == INVALID_HANDLE ||
       g_rsi_handle == INVALID_HANDLE || g_macd_handle == INVALID_HANDLE ||
       g_stoch_handle == INVALID_HANDLE || g_bb_handle == INVALID_HANDLE ||
       g_adx_handle == INVALID_HANDLE) {
        Print("ERROR: Failed to initialize M5 indicators");
        return false;
    }
    
    if(g_params.useMultiTimeframe) {
        if(g_emaFastM15_handle == INVALID_HANDLE || g_emaSlowM15_handle == INVALID_HANDLE) {
            Print("ERROR: Failed to initialize M15 indicators");
            return false;
        }
    }
    
    g_initialized = true;
    Print("✅ Binary M5 Signal System initialized successfully for ", symbol);
    return true;
}

//+------------------------------------------------------------------+
//| Set Default Parameters for M5                                   |
//+------------------------------------------------------------------+
void SetDefaultParametersM5() {
    // Adjusted parameters for M5 timeframe
    g_params.emaFast = 13;              // Faster than M1
    g_params.emaSlow = 34;              // Faster than M1
    g_params.rsiPeriod = 14;
    g_params.macdFast = 8;              // Faster settings
    g_params.macdSlow = 17;             // Faster settings
    g_params.macdSignal = 9;
    g_params.stochK = 14;
    g_params.stochD = 3;
    g_params.stochSlowing = 3;
    g_params.bbPeriod = 20;
    g_params.bbDeviation = 2.0;
    g_params.adxPeriod = 14;
    g_params.volumeMAPeriod = 14;       // Shorter period for M5
    g_params.minConfidence = 65.0;      // Slightly lower for M5
    g_params.strongSignalThreshold = 65.0;
    g_params.moderateSignalThreshold = 55.0;
    g_params.weakSignalThreshold = 45.0;
    g_params.useMultiTimeframe = true;
    g_params.useVolumeFilter = true;
    g_params.useADXFilter = true;
    g_params.minADXLevel = 23.0;        // Slightly lower for M5
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
    
    // Calculate total score
    signal.totalScore = signal.trendScore + signal.momentumScore + signal.oscillatorScore + signal.volumeScore;
    signal.confidence = MathAbs(signal.totalScore);
    
    // Apply confirmation filters
    signal.m15Confirmed = CheckM15TrendAlignment(signal.totalScore, symbol);
    signal.adxConfirmed = CheckADXStrengthM5(symbol);
    signal.volumeConfirmed = CheckVolumeConfirmationM5(symbol);
    
    // Determine signal direction and strength
    DetermineSignalDirectionAndStrengthM5(signal);
    
    // Validate signal
    signal.isValid = ValidateSignalM5(signal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| Calculate Trend Score                                            |
//+------------------------------------------------------------------+
double CalculateTrendScoreM5(string symbol) {
    double emaFast[], emaSlow[];
    
    if(CopyBuffer(g_emaFast_handle, 0, DataIndex, 1, emaFast) <= 0 ||
       CopyBuffer(g_emaSlow_handle, 0, DataIndex, 1, emaSlow) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    
    // EMA Cross Score (±30 points for M5)
    if(emaFast[0] > emaSlow[0]) {
        score += 30.0;
    } else if(emaFast[0] < emaSlow[0]) {
        score -= 30.0;
    }
    
    // EMA Distance Score (±20 points for M5)
    double distance = MathAbs(emaFast[0] - emaSlow[0]) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    double normalizedDistance = MathMin(distance / 150.0, 1.0); // Adjusted for M5
    
    if(emaFast[0] > emaSlow[0]) {
        score += normalizedDistance * 20.0;
    } else {
        score -= normalizedDistance * 20.0;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate Momentum Score                                         |
//+------------------------------------------------------------------+
double CalculateMomentumScoreM5(string symbol) {
    double rsi[], macdMain[], macdSignal[];
    
    if(CopyBuffer(g_rsi_handle, 0, DataIndex, 1, rsi) <= 0 ||
       CopyBuffer(g_macd_handle, 0, DataIndex, 1, macdMain) <= 0 ||
       CopyBuffer(g_macd_handle, 1, DataIndex, 1, macdSignal) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    
    // RSI Score (±20 points for M5)
    if(rsi[0] > 55.0 && rsi[0] < 75.0) {
        score += 20.0;
    } else if(rsi[0] < 45.0 && rsi[0] > 25.0) {
        score -= 20.0;
    } else if(rsi[0] >= 75.0) {
        score -= 10.0; // Overbought penalty
    } else if(rsi[0] <= 25.0) {
        score += 10.0; // Oversold bonus
    }
    
    // MACD Score (±20 points for M5)
    if(macdMain[0] > macdSignal[0] && macdMain[0] > 0) {
        score += 20.0;
    } else if(macdMain[0] < macdSignal[0] && macdMain[0] < 0) {
        score -= 20.0;
    } else if(macdMain[0] > macdSignal[0] && macdMain[0] <= 0) {
        score += 15.0;
    } else if(macdMain[0] < macdSignal[0] && macdMain[0] >= 0) {
        score -= 15.0;
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate Oscillator Score                                       |
//+------------------------------------------------------------------+
double CalculateOscillatorScoreM5(string symbol) {
    double stochK[], stochD[], bbUpper[], bbMiddle[], bbLower[];
    double closePrice = iClose(symbol, PERIOD_M5, DataIndex);
    
    if(CopyBuffer(g_stoch_handle, 0, DataIndex, 1, stochK) <= 0 ||
       CopyBuffer(g_stoch_handle, 1, DataIndex, 1, stochD) <= 0 ||
       CopyBuffer(g_bb_handle, 0, DataIndex, 1, bbUpper) <= 0 ||
       CopyBuffer(g_bb_handle, 1, DataIndex, 1, bbMiddle) <= 0 ||
       CopyBuffer(g_bb_handle, 2, DataIndex, 1, bbLower) <= 0) {
        return 0.0;
    }
    
    double score = 0.0;
    
    // Stochastic Score (±15 points for M5)
    if(stochK[0] > stochD[0] && stochK[0] > 50.0 && stochK[0] < 80.0) {
        score += 15.0;
    } else if(stochK[0] < stochD[0] && stochK[0] < 50.0 && stochK[0] > 20.0) {
        score -= 15.0;
    }
    
    // Bollinger Bands Score (±15 points for M5)
    if(closePrice > bbMiddle[0] && closePrice < bbUpper[0]) {
        score += 15.0;
    } else if(closePrice < bbMiddle[0] && closePrice > bbLower[0]) {
        score -= 15.0;
    } else if(closePrice >= bbUpper[0]) {
        score -= 8.0; // Overbought
    } else if(closePrice <= bbLower[0]) {
        score += 8.0; // Oversold
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate Volume Score                                           |
//+------------------------------------------------------------------+
double CalculateVolumeScoreM5(string symbol) {
    if(!g_params.useVolumeFilter) return 0.0;
    
    // Get current volume
    long currentVolume = iVolume(symbol, PERIOD_M5, DataIndex);
    
    // Calculate average volume manually from recent bars
    long totalVolume = 0;
    int validBars = 0;
    
    for(int i = DataIndex; i <= g_params.volumeMAPeriod + DataIndex - 1; i++) {
        long barVolume = iVolume(symbol, PERIOD_M5, i);
        if(barVolume > 0) {
            totalVolume += barVolume;
            validBars++;
        }
    }
    
    if(validBars == 0) return 0.0;
    
    double avgVolume = (double)totalVolume / validBars;
    double score = 0.0;
    
    // Volume confirmation (±10 points)
    if(currentVolume > avgVolume * 1.4) {      // Higher threshold for M5
        score += 10.0; // High volume
    } else if(currentVolume > avgVolume * 1.2) {
        score += 6.0;  // Above average volume
    } else if(currentVolume < avgVolume * 0.6) {
        score -= 6.0;  // Low volume penalty
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
//| Determine Signal Direction and Strength                          |
//+------------------------------------------------------------------+
void DetermineSignalDirectionAndStrengthM5(BinarySignal &signal) {
    double totalScore = signal.totalScore;
    
    // Determine direction and strength based on score and confirmations
    if(totalScore >= g_params.strongSignalThreshold && signal.m15Confirmed && signal.adxConfirmed) {
        signal.direction = SIGNAL_CALL;
        signal.strength = STRENGTH_STRONG;
        signal.reason = StringFormat("STRONG CALL M5 - Score: %.1f (T:%.1f M:%.1f O:%.1f V:%.1f)", 
                                   totalScore, signal.trendScore, signal.momentumScore, 
                                   signal.oscillatorScore, signal.volumeScore);
    }
    else if(totalScore <= -g_params.strongSignalThreshold && signal.m15Confirmed && signal.adxConfirmed) {
        signal.direction = SIGNAL_PUT;
        signal.strength = STRENGTH_STRONG;
        signal.reason = StringFormat("STRONG PUT M5 - Score: %.1f (T:%.1f M:%.1f O:%.1f V:%.1f)", 
                                   totalScore, signal.trendScore, signal.momentumScore, 
                                   signal.oscillatorScore, signal.volumeScore);
    }
    else if(totalScore >= g_params.moderateSignalThreshold && signal.m15Confirmed) {
        signal.direction = SIGNAL_CALL;
        signal.strength = STRENGTH_MODERATE;
        signal.reason = StringFormat("MODERATE CALL M5 - Score: %.1f", totalScore);
    }
    else if(totalScore <= -g_params.moderateSignalThreshold && signal.m15Confirmed) {
        signal.direction = SIGNAL_PUT;
        signal.strength = STRENGTH_MODERATE;
        signal.reason = StringFormat("MODERATE PUT M5 - Score: %.1f", totalScore);
    }
    else if(totalScore >= g_params.weakSignalThreshold) {
        signal.direction = SIGNAL_CALL;
        signal.strength = STRENGTH_WEAK;
        signal.reason = StringFormat("WEAK CALL M5 - Score: %.1f", totalScore);
    }
    else if(totalScore <= -g_params.weakSignalThreshold) {
        signal.direction = SIGNAL_PUT;
        signal.strength = STRENGTH_WEAK;
        signal.reason = StringFormat("WEAK PUT M5 - Score: %.1f", totalScore);
    }
    else {
        signal.direction = SIGNAL_NONE;
        signal.strength = STRENGTH_WEAK;
        signal.reason = StringFormat("NO SIGNAL M5 - Score: %.1f (insufficient strength)", totalScore);
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
    
    g_initialized = false;
    Print("Binary M5 Signal System cleaned up");
}

//+------------------------------------------------------------------+
//| Quick Signal Check (Simple version)                             |
//+------------------------------------------------------------------+
int GetQuickSignalM5(string symbol = "", double minConfidence = 65.0) {
    BinarySignal signal = GetBinarySignalM5(symbol);
    
    if(signal.isValid && signal.confidence >= minConfidence) {
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