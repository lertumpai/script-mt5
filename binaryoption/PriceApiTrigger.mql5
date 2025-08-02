#property copyright "New"
#property version   "1.09"
#property script_show_inputs

#include "../Include/Lertumpai/price.mqh"

input bool enable_realtime_updates = true; // Enable/disable real-time updates for all timeframes
input bool enable_historical_bulk_send = true; // Enable/disable historical bulk send on init


int OnInit()
  {
   string my_symbol = StandardizeSymbol(Symbol());
   Print("EA Initialized for symbol: ", my_symbol, " (Original: ", Symbol(), ")");
   Print("Real-time updates for ALL timeframes: ", enable_realtime_updates ? "ENABLED" : "DISABLED");
   Print("Real-time throttle: ", realtime_throttle_seconds, " seconds");
   Print("Historical bulk send: ", enable_historical_bulk_send ? "ENABLED" : "DISABLED");
   
   if(enable_historical_bulk_send)
     {
      Print("Historical bars config: M1=", historical_bars_M1, ", M5=", historical_bars_M5, ", M15=", historical_bars_M15, 
            ", M30=", historical_bars_M30, ", H1=", historical_bars_H1, ", H4=", historical_bars_H4, ", D=", historical_bars_D);
      Print("Bulk send batch size: ", bulk_send_batch_size);
      
      // Send historical data for all timeframes
      SendHistoricalDataAllTimeframes();
     }
   
   // Send initial real-time data for all timeframes
   if(enable_realtime_updates)
     {
      SendRealtimeAllTimeframes();
     }
   
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   // Send real-time price updates for all timeframes if enabled
   if(enable_realtime_updates)
     {
      SendRealtimeAllTimeframes();
     }
  }

