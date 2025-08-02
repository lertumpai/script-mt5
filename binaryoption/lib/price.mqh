#property copyright "Lertumpai"
#property link      "https://www.mql5.com"

#include "./api.mqh"

// Real-time update tracking
datetime last_realtime_update = 0;
input int realtime_throttle_seconds = 1; // Minimum seconds between real-time updates

input int historical_bars_M1 = 2880;   // Number of M1 bars to send (48 hours)
input int historical_bars_M5 = 576;    // Number of M5 bars to send (48 hours)
input int historical_bars_M15 = 192;   // Number of M15 bars to send (48 hours)
input int historical_bars_M30 = 96;    // Number of M30 bars to send (48 hours)
input int historical_bars_H1 = 48;     // Number of H1 bars to send (48 hours)
input int historical_bars_H4 = 12;     // Number of H4 bars to send (48 hours)
input int historical_bars_D = 2;       // Number of D bars to send (48 hours)
input int bulk_send_batch_size = 100;  // Number of records per batch when sending historical data

string TimeframeToString(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:   return "M1";
      case PERIOD_M5:   return "M5";
      case PERIOD_M15:  return "M15";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H4:   return "H4";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return "UNKNOWN";
   }
}


// Function to standardize symbol to exactly 6 characters
string StandardizeSymbol(string original_symbol)
  {
   string standardized = original_symbol;
   
   // Remove any spaces or special characters
   StringReplace(standardized, " ", "");
   StringReplace(standardized, ".", "");
   StringReplace(standardized, "-", "");
   StringReplace(standardized, "_", "");
   
   // Ensure exactly 6 characters
   if(StringLen(standardized) > 6)
     {
      // Truncate to 6 characters
      standardized = StringSubstr(standardized, 0, 6);
     }
   else if(StringLen(standardized) < 6)
     {
      // Pad with spaces to make it 6 characters
      while(StringLen(standardized) < 6)
        {
         standardized += " ";
        }
     }
   
   // Convert to uppercase for consistency
   StringToUpper(standardized);
   
   return standardized;
  }

void SendHistoricalDataAllTimeframes()
  {
   string my_symbol = StandardizeSymbol(Symbol());
   Print("Starting historical bulk data send for symbol: ", my_symbol);
   
   // Send historical data for each timeframe
   if(historical_bars_M1 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_M1, TimeframeToString(PERIOD_M1), historical_bars_M1);
   
   if(historical_bars_M5 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_M5, TimeframeToString(PERIOD_M5), historical_bars_M5);
   
   if(historical_bars_M15 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_M15, TimeframeToString(PERIOD_M15), historical_bars_M15);
   
   if(historical_bars_M30 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_M30, TimeframeToString(PERIOD_M30), historical_bars_M30);
   
   if(historical_bars_H1 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_H1, TimeframeToString(PERIOD_H1), historical_bars_H1);
   
   if(historical_bars_H4 > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_H4, TimeframeToString(PERIOD_H4), historical_bars_H4);
   
   if(historical_bars_D > 0)
     SendHistoricalDataForTimeframe(my_symbol, PERIOD_D1, TimeframeToString(PERIOD_D1), historical_bars_D);
   
   Print("Historical bulk data send completed for all timeframes");
  }

void SendHistoricalDataForTimeframe(string symbol, ENUM_TIMEFRAMES period, string tf_name, int bars_count)
  {
   Print("Sending ", bars_count, " historical ", tf_name, " bars...");
   
   string original_symbol = Symbol();
   int total_sent = 0;
   int batch_count = 0;
   
   // Send data in batches to avoid overwhelming the API
   for(int start_bar = bars_count - 1; start_bar >= 0; start_bar -= bulk_send_batch_size)
     {
      int end_bar = MathMax(0, start_bar - bulk_send_batch_size + 1);
      int current_batch_size = start_bar - end_bar + 1;
      
      string prices_json = "";
      int records_in_batch = 0;
      
      // Build batch of historical records (from oldest to newest in this batch)
      for(int bar = start_bar; bar >= end_bar; bar--)
        {
         datetime bar_time = iTime(original_symbol, period, bar);
         double open_price = iOpen(original_symbol, period, bar);
         double high_price = iHigh(original_symbol, period, bar);
         double low_price = iLow(original_symbol, period, bar);
         double close_price = iClose(original_symbol, period, bar);
         
         // Skip if any price is invalid or bar time is invalid
         if(open_price <= 0 || high_price <= 0 || low_price <= 0 || close_price <= 0 || bar_time <= 0)
           {
            continue;
           }
         
         // Format datetime as ISO 8601 string
         string price_datetime = TimeToString(bar_time, TIME_DATE|TIME_SECONDS);
         StringReplace(price_datetime, " ", "T");
         StringReplace(price_datetime, ".", "-");
         price_datetime += ".000Z";
         
         // Add comma separator if not first record in batch
         if(records_in_batch > 0)
           {
            prices_json += ",";
           }
         
         // Build JSON for this price record
         string price_record = StringFormat(
            "{\"symbol\":\"%s\",\"open\":%.5f,\"high\":%.5f,\"low\":%.5f,\"close\":%.5f,\"timeframe\":\"%s\",\"priceDateTime\":\"%s\"}",
            symbol, open_price, high_price, low_price, close_price, tf_name, price_datetime
         );
         
         prices_json += price_record;
         records_in_batch++;
        }
      
      // Send this batch if we have records
      if(records_in_batch > 0)
        {
         string batch_json = "{\"prices\":[" + prices_json + "]}";
         Print("Sending ", tf_name, " batch ", ++batch_count, " with ", records_in_batch, " records (bars ", end_bar, " to ", start_bar, ")");
         
         CallBulkUpdatePriceApi(batch_json);
         total_sent += records_in_batch;
         
         // Small delay between batches to avoid overwhelming the server
         Sleep(100);
        }
     }
   
   Print("Historical ", tf_name, " data complete: ", total_sent, " records sent in ", batch_count, " batches");
  }

void SendRealtimeAllTimeframes()
  {
   string my_symbol = StandardizeSymbol(Symbol());
   datetime current_time = TimeCurrent();
   
   // Check throttle - don't send more often than specified interval
   if(current_time - last_realtime_update < realtime_throttle_seconds)
     {
      return;
     }
   
   string prices_json = "";
   int price_count = 0;
   
   // Get real-time data for all timeframes
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_M1, TimeframeToString(PERIOD_M1), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_M5, TimeframeToString(PERIOD_M5), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_M15, TimeframeToString(PERIOD_M15), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_M30, TimeframeToString(PERIOD_M30), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_H1, TimeframeToString(PERIOD_H1), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_H4, TimeframeToString(PERIOD_H4), prices_json, price_count);
   price_count += GetRealtimeTimeframeData(my_symbol, PERIOD_D1, TimeframeToString(PERIOD_D1), prices_json, price_count);
   
   // Send bulk real-time data if we have any prices
   if(price_count > 0)
     {
      string full_json = "{\"prices\":[" + prices_json + "]}";
      Print("Sending real-time update for ", price_count, " timeframes.");
      CallBulkUpdatePriceApi(full_json);
      
      // Update tracking variables
      last_realtime_update = current_time;
     }
  }

int GetRealtimeTimeframeData(string symbol, ENUM_TIMEFRAMES period, string tf_name, string &prices_json, int existing_count)
  {
   // Get current bar data for this timeframe - use original symbol for MT5 functions
   string original_symbol = Symbol();
   datetime current_bar_time = iTime(original_symbol, period, 0);
   double open_price = iOpen(original_symbol, period, 0);
   double high_price = iHigh(original_symbol, period, 0);
   double low_price = iLow(original_symbol, period, 0);
   double close_price = iClose(original_symbol, period, 0);
   
   // Skip if any price is invalid
   if(open_price <= 0 || high_price <= 0 || low_price <= 0 || close_price <= 0)
     {
      Print("Invalid real-time price data for ", tf_name, ". Skipping...");
      return 0;
     }
   
   // Format datetime as ISO 8601 string - use current time for real-time data
   string price_datetime = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   // Replace space with T for ISO 8601 format
   StringReplace(price_datetime, " ", "T");
   // Replace dots with hyphens in date part for valid ISO 8601 format
   StringReplace(price_datetime, ".", "-");
   // Add milliseconds and Z suffix
   price_datetime += ".000Z";
   
   // Add comma separator if not first price
   if(existing_count > 0)
     {
      prices_json += ",";
     }
   
   // Build JSON for this price record - use standardized symbol
   string price_record = StringFormat(
      "{\"symbol\":\"%s\",\"open\":%.5f,\"high\":%.5f,\"low\":%.5f,\"close\":%.5f,\"timeframe\":\"%s\",\"priceDateTime\":\"%s\"}",
      symbol, open_price, high_price, low_price, close_price, tf_name, price_datetime
   );
   
   prices_json += price_record;
   
   Print("Real-time ", tf_name, ": O=", open_price, " H=", high_price, " L=", low_price, " C=", close_price, " (Bar Data)");
   
   return 1; // Successfully added one record
  }

