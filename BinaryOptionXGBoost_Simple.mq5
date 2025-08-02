//+------------------------------------------------------------------+
//|                              BinaryOptionXGBoost_Simple.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Include XGBoost Signal Library
#include "XGBoostSignalLibrary.mqh"

//--- input parameters
input double InpLotSize = 0.1;        // Lot size
input int    InpMagic = 12345;        // Magic number
input int    InpExpirationMinutes = 5; // Binary option expiration (minutes)
input bool   InpEnableTrading = false; // Enable actual trading
input int    InpMaxOrders = 1;        // Maximum concurrent orders

//--- global variables
int g_order_count = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== Binary Option XGBoost Simple EA Started ===");
    
    // ตรวจสอบ timeframe
    if(Period() != PERIOD_M1)
    {
        Print("ERROR: This EA is designed for M1 timeframe only!");
        return INIT_FAILED;
    }
    
    // Initialize XGBoost Library
    InitXGBoostLibrary();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== Binary Option XGBoost Simple EA Stopped ===");
    Print("Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{
    // ตรวจสอบว่าเป็นเวลาที่เหมาะสมหรือไม่
    if(!IsTradeAllowed()) return;
    
    // ตรวจสอบจำนวน orders
    if(g_order_count >= InpMaxOrders) return;
    
    // ใช้ Library function หลัก
    int signal = GetSignal();
    
    // ส่งสัญญาณ
    if(signal != 0)
    {
        if(signal == 1)
        {
            Print("=== SIGNAL: CALL ===");
            if(InpEnableTrading)
                PlaceBinaryOption(ORDER_TYPE_BUY, "CALL");
        }
        else if(signal == -1)
        {
            Print("=== SIGNAL: PUT ===");
            if(InpEnableTrading)
                PlaceBinaryOption(ORDER_TYPE_SELL, "PUT");
        }
    }
}

//+------------------------------------------------------------------+
//| Place Binary Option Order                                     |
//+------------------------------------------------------------------+
void PlaceBinaryOption(ENUM_ORDER_TYPE order_type, string signal_type)
{
    Print("Placing ", signal_type, " order...");
    
    // ตัวอย่างการวาง order (ต้องปรับตาม broker)
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = InpLotSize;
    request.type = order_type;
    request.price = (order_type == ORDER_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request.deviation = 5;
    request.magic = InpMagic;
    request.comment = "XGBoost " + signal_type;
    
    if(OrderSend(request, result))
    {
        Print("Order placed successfully: ", signal_type);
        g_order_count++;
    }
    else
    {
        Print("Order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Check and update order count                                  |
//+------------------------------------------------------------------+
void OnTrade()
{
    // อัพเดทจำนวน orders ที่เปิดอยู่
    g_order_count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(OrderGetTicket(i)))
        {
            if(OrderGetInteger(ORDER_MAGIC) == InpMagic)
            {
                g_order_count++;
            }
        }
    }
}

//+------------------------------------------------------------------+ 