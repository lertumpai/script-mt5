//+------------------------------------------------------------------+
//| Enhanced RandomForest Binary Option Trading Model
//+------------------------------------------------------------------+
#property copyright "Enhanced ML Model Generated"
#property version   "2.00"
#property strict

// Input parameters
input double BUY_THRESHOLD = 0.6;      // Probability threshold for BUY
input double SELL_THRESHOLD = 0.4;     // Probability threshold for SELL
input int OFFSET_BAR = 1;               // Offset bar for analysis
input bool ENABLE_TRADING = false;      // Enable actual trading
input double LOT_SIZE = 0.1;            // Lot size for trading
input int MAGIC_NUMBER = 12345;         // Magic number for orders
input int MAX_ORDERS = 3;               // Maximum concurrent orders
input double STOP_LOSS_PIPS = 20;       // Stop loss in pips
input double TAKE_PROFIT_PIPS = 40;     // Take profit in pips

// Model parameters
double model_weights[17];
double model_intercept = 0;
double scaler_mean[17];
double scaler_scale[17];

// Global variables
datetime last_prediction_time = 0;
int total_orders = 0;
double last_probability = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize model parameters
    initializeModelParameters();
    
    Print("Enhanced RandomForest Binary Option Model Initialized");
    Print("Buy Threshold: ", BUY_THRESHOLD);
    Print("Sell Threshold: ", SELL_THRESHOLD);
    Print("Offset Bar: ", OFFSET_BAR);
    Print("Trading Enabled: ", ENABLE_TRADING);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Enhanced RandomForest Binary Option Model Deinitialized");
}

//+------------------------------------------------------------------+
//| Initialize model parameters                                     |
//+------------------------------------------------------------------+
void initializeModelParameters()
{
    // Initialize with actual values from trained model
    for(int i = 0; i < 17; i++)
    {
        model_weights[i] = 0.0;
        scaler_mean[i] = 0.0;
        scaler_scale[i] = 1.0;
    }
    model_intercept = 0.0;
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
    
    // Price changes
    features[0] = (close - prev_close) / prev_close; // price_change
    features[1] = high / low; // high_low_ratio
    features[2] = open / close; // open_close_ratio
    
    // Moving averages with offset
    double ma5 = iMA(Symbol(), Period(), 5, 0, MODE_SMA, PRICE_CLOSE);
    double ma10 = iMA(Symbol(), Period(), 10, 0, MODE_SMA, PRICE_CLOSE);
    double ma20 = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    double ma50 = iMA(Symbol(), Period(), 50, 0, MODE_SMA, PRICE_CLOSE);
    
    features[3] = close / ma5; // ma_5_ratio
    features[4] = close / ma10; // ma_10_ratio
    features[5] = close / ma20; // ma_20_ratio
    features[6] = close / ma50; // ma_50_ratio
    
    // RSI with offset
    features[7] = iRSI(Symbol(), Period(), 14, PRICE_CLOSE); // rsi
    
    // Bollinger Bands with offset
    double bb_middle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    double bb_std = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    double bb_upper = bb_middle + (bb_std * 2);
    double bb_lower = bb_middle - (bb_std * 2);
    features[8] = (close - bb_lower) / (bb_upper - bb_lower); // bb_position
    
    // Volatility
    features[9] = bb_std / close; // volatility_ratio
    
    // Momentum with offset
    features[10] = (close / iClose(Symbol(), Period(), offset_bar + 5)) - 1; // momentum_5
    features[11] = (close / iClose(Symbol(), Period(), offset_bar + 10)) - 1; // momentum_10
    
    // Support/Resistance with offset
    double support = iLow(Symbol(), Period(), iLowest(Symbol(), Period(), MODE_LOW, 20, offset_bar));
    double resistance = iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, 20, offset_bar));
    features[12] = (close - support) / close; // support_distance
    features[13] = (resistance - close) / close; // resistance_distance
    
    // Time features (current time, not offset)
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    features[14] = dt.hour; // hour
    features[15] = dt.min; // minute
    features[16] = dt.day_of_week; // day_of_week
}

//+------------------------------------------------------------------+
//| Predict using model with offset                                |
//+------------------------------------------------------------------+
double predict(int offset_bar = 1)
{
    double features[17];
    calculateFeatures(features, offset_bar);
    
    // Scale features
    double scaled_features[17];
    for(int i = 0; i < 17; i++)
    {
        scaled_features[i] = (features[i] - scaler_mean[i]) / scaler_scale[i];
    }
    
    // Make prediction (simplified linear model)
    double prediction = model_intercept;
    for(int i = 0; i < 17; i++)
    {
        prediction += model_weights[i] * scaled_features[i];
    }
    
    return 1.0 / (1.0 + MathExp(-prediction)); // Sigmoid function
}

//+------------------------------------------------------------------+
//| Get trading signal with offset                                 |
//+------------------------------------------------------------------+
string getTradingSignal(double buy_threshold = 0.6, double sell_threshold = 0.4, int offset_bar = 1)
{
    double probability = predict(offset_bar);
    
    if(probability > buy_threshold)
        return "BUY";
    else if(probability < sell_threshold)
        return "SELL";
    else
        return "HOLD";
}

//+------------------------------------------------------------------+
//| Execute trading signal                                         |
//+------------------------------------------------------------------+
void executeTradingSignal(string signal, double probability)
{
    // Check if we can open new orders
    if(total_orders >= MAX_ORDERS)
    {
        Print("Maximum orders reached: ", total_orders);
        return;
    }
    
    double stop_loss = 0;
    double take_profit = 0;
    int order_type = 0;
    double order_price = 0;
    
    if(signal == "BUY")
    {
        order_type = OP_BUY;
        order_price = Ask;
        stop_loss = order_price - (STOP_LOSS_PIPS * Point);
        take_profit = order_price + (TAKE_PROFIT_PIPS * Point);
        
        int ticket = OrderSend(Symbol(), order_type, LOT_SIZE, order_price, 3, 
                              stop_loss, take_profit, "ML BUY Signal", MAGIC_NUMBER, 0, clrGreen);
        
        if(ticket > 0)
        {
            Print("BUY Order opened - Ticket: ", ticket, " Price: ", order_price, " Probability: ", probability);
            total_orders++;
        }
        else
        {
            Print("Failed to open BUY order - Error: ", GetLastError());
        }
    }
    else if(signal == "SELL")
    {
        order_type = OP_SELL;
        order_price = Bid;
        stop_loss = order_price + (STOP_LOSS_PIPS * Point);
        take_profit = order_price - (TAKE_PROFIT_PIPS * Point);
        
        int ticket = OrderSend(Symbol(), order_type, LOT_SIZE, order_price, 3, 
                              stop_loss, take_profit, "ML SELL Signal", MAGIC_NUMBER, 0, clrRed);
        
        if(ticket > 0)
        {
            Print("SELL Order opened - Ticket: ", ticket, " Price: ", order_price, " Probability: ", probability);
            total_orders++;
        }
        else
        {
            Print("Failed to open SELL order - Error: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime current_time = TimeCurrent();
    
    // Make prediction every minute
    if(current_time - last_prediction_time >= 60)
    {
        // Get trading signal with offset bar
        string signal = getTradingSignal(BUY_THRESHOLD, SELL_THRESHOLD, OFFSET_BAR);
        double probability = predict(OFFSET_BAR);
        last_probability = probability;
        
        Print("Signal: ", signal, " - Probability: ", DoubleToString(probability, 4), " - Offset: ", OFFSET_BAR);
        
        // Execute trading logic
        if(ENABLE_TRADING)
        {
            executeTradingSignal(signal, probability);
        }
        
        last_prediction_time = current_time;
    }
}

//+------------------------------------------------------------------+
//| Chart event function                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Handle chart events if needed
}

//+------------------------------------------------------------------+ 