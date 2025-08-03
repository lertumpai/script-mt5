
//+------------------------------------------------------------------+
//| Enhanced ExtraTrees Binary Option Library
//+------------------------------------------------------------------+
#property copyright "Enhanced ML Model Library"
#property version   "2.00"
#property library
#property strict

// Model parameters
double model_weights[14];
double model_intercept = 0;
double scaler_center[14];
double scaler_scale[14];

// External indicator handles (will be set by EA)
int g_ma5_handle = INVALID_HANDLE;
int g_ma10_handle = INVALID_HANDLE;
int g_ma20_handle = INVALID_HANDLE;
int g_ma50_handle = INVALID_HANDLE;
int g_rsi_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;
int g_std_dev_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Initialize model parameters                                     |
//+------------------------------------------------------------------+
void initializeModelParameters()
{
    // Initialize with actual values from trained model
    for(int i = 0; i < 14; i++)
    {
        scaler_center[i] = 0.0;
        scaler_scale[i] = 1.0;
        model_weights[i] = 0.0;
    }
    model_intercept = 0.0;
}

//+------------------------------------------------------------------+
//| Set indicator handles                                          |
//+------------------------------------------------------------------+
void setIndicatorHandles(int ma5_h, int ma10_h, int ma20_h, int ma50_h, 
                        int rsi_h, int bb_h, int std_dev_h)
{
    g_ma5_handle = ma5_h;
    g_ma10_handle = ma10_h;
    g_ma20_handle = ma20_h;
    g_ma50_handle = ma50_h;
    g_rsi_handle = rsi_h;
    g_bb_handle = bb_h;
    g_std_dev_handle = std_dev_h;
}

//+------------------------------------------------------------------+
//| Calculate features with offset                                 |
//+------------------------------------------------------------------+
void calculateFeatures(double &features[], int offset_bar = 1)
{
    double close = iClose(Symbol(), Period(), offset_bar);
    double open = iOpen(Symbol(), Period(), offset_bar);
    double high = iHigh(Symbol(), Period(), offset_bar);
    double low = iLow(Symbol(), Period(), offset_bar);
    double prev_close = iClose(Symbol(), Period(), offset_bar + 1);
    
    // Price features
    features[0] = (close - prev_close) / prev_close;
    features[1] = high / low;
    features[2] = MathAbs(close - open) / close;
    
    // Moving averages with offset
    double ma5_buffer[1], ma10_buffer[1], ma20_buffer[1], ma50_buffer[1];
    
    if(g_ma5_handle != INVALID_HANDLE)
        CopyBuffer(g_ma5_handle, 0, offset_bar, 1, ma5_buffer);
    else
        ma5_buffer[0] = iMA(Symbol(), Period(), 5, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
        
    if(g_ma10_handle != INVALID_HANDLE)
        CopyBuffer(g_ma10_handle, 0, offset_bar, 1, ma10_buffer);
    else
        ma10_buffer[0] = iMA(Symbol(), Period(), 10, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
        
    if(g_ma20_handle != INVALID_HANDLE)
        CopyBuffer(g_ma20_handle, 0, offset_bar, 1, ma20_buffer);
    else
        ma20_buffer[0] = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
        
    if(g_ma50_handle != INVALID_HANDLE)
        CopyBuffer(g_ma50_handle, 0, offset_bar, 1, ma50_buffer);
    else
        ma50_buffer[0] = iMA(Symbol(), Period(), 50, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
    
    features[3] = close / ma5_buffer[0];
    features[4] = close / ma10_buffer[0];
    features[5] = close / ma20_buffer[0];
    features[6] = close / ma50_buffer[0];
    
    // RSI with offset
    double rsi_buffer[1];
    if(g_rsi_handle != INVALID_HANDLE)
        CopyBuffer(g_rsi_handle, 0, offset_bar, 1, rsi_buffer);
    else
        rsi_buffer[0] = iRSI(Symbol(), Period(), 14, PRICE_CLOSE, offset_bar);
    features[7] = rsi_buffer[0];
    
    // Bollinger Bands with offset
    double bb_buffer[1], std_dev_buffer[1];
    if(g_bb_handle != INVALID_HANDLE)
        CopyBuffer(g_bb_handle, 0, offset_bar, 1, bb_buffer);
    else
        bb_buffer[0] = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
        
    if(g_std_dev_handle != INVALID_HANDLE)
        CopyBuffer(g_std_dev_handle, 0, offset_bar, 1, std_dev_buffer);
    else
        std_dev_buffer[0] = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, offset_bar);
    
    double bb_upper = bb_buffer[0] + (std_dev_buffer[0] * 2);
    double bb_lower = bb_buffer[0] - (std_dev_buffer[0] * 2);
    features[8] = (close - bb_lower) / (bb_upper - bb_lower);
    
    // Momentum with offset
    features[9] = (close / iClose(Symbol(), Period(), offset_bar + 5)) - 1;
    features[10] = (close / iClose(Symbol(), Period(), offset_bar + 10)) - 1;
    
    // Volatility with offset
    features[11] = std_dev_buffer[0] / close;
    
    // Time features (current time, not offset)
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    features[12] = dt.hour;
    features[13] = dt.day_of_week;
}

//+------------------------------------------------------------------+
//| Predict probability with offset                                |
//+------------------------------------------------------------------+
double predictProbability(int offset_bar = 1)
{
    double features[14];
    calculateFeatures(features, offset_bar);
    
    // Scale features
    double scaled_features[14];
    for(int i = 0; i < 14; i++)
    {
        scaled_features[i] = (features[i] - scaler_center[i]) / scaler_scale[i];
    }
    
    // Make prediction
    double prediction = model_intercept;
    for(int i = 0; i < 14; i++)
    {
        prediction += model_weights[i] * scaled_features[i];
    }
    
    return 1.0 / (1.0 + MathExp(-prediction));
}

//+------------------------------------------------------------------+
//| Get trading signal with offset                                 |
//+------------------------------------------------------------------+
string getTradingSignal(double buy_threshold = 0.6, double sell_threshold = 0.4, int offset_bar = 1)
{
    double probability = predictProbability(offset_bar);
    
    if(probability > buy_threshold)
        return "BUY";
    else if(probability < sell_threshold)
        return "SELL";
    else
        return "HOLD";
}

//+------------------------------------------------------------------+
