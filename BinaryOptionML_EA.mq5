//+------------------------------------------------------------------+
//| Binary Option ML Trading Expert Advisor
//+------------------------------------------------------------------+
#property copyright "ML Binary Option Trading EA"
#property version   "1.00"
#property strict

// Include the ML library
#include "enhanced_extratrees_library.mqh"

// Input parameters
input double BUY_THRESHOLD = 0.6;      // Probability threshold for BUY
input double SELL_THRESHOLD = 0.4;     // Probability threshold for SELL
input int PREDICTION_PERIOD = 5;        // Minutes to predict ahead
input bool ENABLE_TRADING = false;      // Enable actual trading
input double LOT_SIZE = 0.1;            // Lot size for trading
input int MAGIC_NUMBER = 12345;         // Magic number for orders
input int MAX_ORDERS = 3;               // Maximum concurrent orders
input double STOP_LOSS_PIPS = 20;       // Stop loss in pips
input double TAKE_PROFIT_PIPS = 40;     // Take profit in pips
input int OFFSET_BAR = 1;               // Offset bar for analysis (T-1 for current, T-2 for analysis)

// Global variables
datetime last_prediction_time = 0;
int total_orders = 0;
double last_probability = 0;

// Indicator handles
int ma5_handle;
int ma10_handle;
int ma20_handle;
int ma50_handle;
int rsi_handle;
int bb_handle;
int std_dev_handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize ML model
    initializeModelParameters();
    
    // Initialize indicators
    ma5_handle = iMA(Symbol(), Period(), 5, 0, MODE_SMA, PRICE_CLOSE);
    ma10_handle = iMA(Symbol(), Period(), 10, 0, MODE_SMA, PRICE_CLOSE);
    ma20_handle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    ma50_handle = iMA(Symbol(), Period(), 50, 0, MODE_SMA, PRICE_CLOSE);
    rsi_handle = iRSI(Symbol(), Period(), 14, PRICE_CLOSE);
    bb_handle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    std_dev_handle = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE);
    
    // Check if indicators are created successfully
    if(ma5_handle == INVALID_HANDLE || ma10_handle == INVALID_HANDLE || 
       ma20_handle == INVALID_HANDLE || ma50_handle == INVALID_HANDLE ||
       rsi_handle == INVALID_HANDLE || bb_handle == INVALID_HANDLE ||
       std_dev_handle == INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }
    
    // Set indicator handles in library
    setIndicatorHandles(ma5_handle, ma10_handle, ma20_handle, ma50_handle,
                       rsi_handle, bb_handle, std_dev_handle);
    
    Print("Binary Option ML Trading EA Initialized");
    Print("Model: Enhanced ExtraTrees");
    Print("Buy Threshold: ", BUY_THRESHOLD);
    Print("Sell Threshold: ", SELL_THRESHOLD);
    Print("Prediction Period: ", PREDICTION_PERIOD, " minutes");
    Print("Trading Enabled: ", ENABLE_TRADING);
    Print("Offset Bar: ", OFFSET_BAR);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(ma5_handle != INVALID_HANDLE) IndicatorRelease(ma5_handle);
    if(ma10_handle != INVALID_HANDLE) IndicatorRelease(ma10_handle);
    if(ma20_handle != INVALID_HANDLE) IndicatorRelease(ma20_handle);
    if(ma50_handle != INVALID_HANDLE) IndicatorRelease(ma50_handle);
    if(rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
    if(bb_handle != INVALID_HANDLE) IndicatorRelease(bb_handle);
    if(std_dev_handle != INVALID_HANDLE) IndicatorRelease(std_dev_handle);
    
    Print("Binary Option ML Trading EA Deinitialized");
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
        double probability = predictProbability(OFFSET_BAR);
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
//| Order management function                                       |
//+------------------------------------------------------------------+
void manageOrders()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC_NUMBER)
            {
                // Check if order is closed
                if(OrderCloseTime() > 0)
                {
                    total_orders--;
                    Print("Order closed - Ticket: ", OrderTicket(), " Profit: ", OrderProfit());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Custom function to get current statistics                       |
//+------------------------------------------------------------------+
void getTradingStatistics()
{
    int total_trades = 0;
    int winning_trades = 0;
    double total_profit = 0;
    
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC_NUMBER)
            {
                total_trades++;
                total_profit += OrderProfit();
                
                if(OrderProfit() > 0)
                    winning_trades++;
            }
        }
    }
    
    if(total_trades > 0)
    {
        double win_rate = (double)winning_trades / total_trades * 100;
        Print("=== Trading Statistics ===");
        Print("Total Trades: ", total_trades);
        Print("Winning Trades: ", winning_trades);
        Print("Win Rate: ", DoubleToString(win_rate, 2), "%");
        Print("Total Profit: ", DoubleToString(total_profit, 2));
        Print("Current Probability: ", DoubleToString(last_probability, 4));
        Print("Active Orders: ", total_orders);
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