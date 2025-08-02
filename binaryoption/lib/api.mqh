#property copyright "Lertumpai"
#property link      "https://www.mql5.com"

input string api_key = "S@rawit5171718";
input string base_url = "http://192.168.1.35:5000";
input string bulk_update_price_path = "/prices/bulk-update";
input string update_price_path = "/prices/update";

int timeout = 10000;

string headers = 
      "Content-Type: application/json\r\n" +
      "Cookie: api_key=" + api_key + "\r\n";

void CallBulkUpdatePriceApi(string json_body)
  {
   string api = base_url + bulk_update_price_path;
  
   uchar post[];
   
   // Print only first 200 characters to avoid log spam with large datasets
   string debug_body = StringLen(json_body) > 200 ? StringSubstr(json_body, 0, 200) + "..." : json_body;
   Print("Bulk POST Body: ", debug_body);
   
   int body_length = StringToCharArray(json_body, post);
   ArrayResize(post, body_length - 1); // Remove trailing null char
   
   uchar result[];
   string result_headers = "";
   
   int res = WebRequest(
      "POST",
      api,
      headers,
      timeout,
      post,
      result,
      result_headers
   );
   
   if(res == -1)
     {
      int error_code = GetLastError();
      Print("WebRequest error: ", error_code);
      
      if(error_code == 4060)
        {
         Print("URL not allowed. Add ", api, " to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
        }
      else
        {
         Print("Other WebRequest error. Check network connection and API server status.");
        }
     }
   else
     {
      string response = CharArrayToString(result);
      
      // Handle different response codes
      if(res != 200 && res != 201)
        {
         Print("API Error - Response Code: ", res);
         Print("API Error Response: ", response);
         
         // Check for specific error messages
         if(StringFind(response, "Prices array cannot be empty") != -1)
           {
            Print("ERROR: Sent empty prices array. Check JSON format.");
           }
         else if(StringFind(response, "Cannot process more than 1000 records") != -1)
           {
            Print("ERROR: Too many records in batch. Reduce bulk_send_batch_size.");
           }
        }
      else
        {
         // Parse successful response
         if(StringFind(response, "\"successful\":") != -1)
           {
            // Extract successful count from bulk response
            int successful_start = StringFind(response, "\"successful\":");
            if(successful_start != -1)
              {
               string temp = StringSubstr(response, successful_start + 13);
               int comma_pos = StringFind(temp, ",");
               if(comma_pos != -1)
                 {
                  string successful_count = StringSubstr(temp, 0, comma_pos);
                  Print("Bulk update: ", successful_count, " records successful");
                 }
              }
           }
         else
           {
            Print("API Success but unexpected response format: ", response);
           }
        }
     }
  }

void CallPriceUpdateAPI(string symbol, double open, double high, double low, double close, string timeframe, string priceDateTime)
{
   string api = base_url + update_price_path;
   
   // Build JSON payload
   string json_body = StringFormat(
      "{\"symbol\":\"%s\",\"open\":%.5f,\"high\":%.5f,\"low\":%.5f,\"close\":%.5f,\"timeframe\":\"%s\",\"priceDateTime\":\"%s\"}",
      symbol, open, high, low, close, timeframe, priceDateTime
   );

   // Convert JSON to byte array
   uchar post[];
   int body_length = StringToCharArray(json_body, post);
   ArrayResize(post, body_length - 1); // Remove trailing null char
   
   // Make HTTP request
   uchar result[];
   string result_headers = "";
   
   int res = WebRequest(
      "POST",
      api,
      headers,
      timeout,
      post,
      result,
      result_headers
   );
   
   // Handle response
   if(res == -1)
   {
      int error_code = GetLastError();
      Print("WebRequest error: ", error_code);
      
      if(error_code == 4060)
      {
         Print("URL not allowed. Add ", api, " to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
      }
      else
      {
         Print("Other WebRequest error. Check network connection and API server status.");
      }
   }
   else
   {
      string response = CharArrayToString(result);
      
      if(res == 200 || res == 201)
      {
         Print("API Success - Response Code: ", res);
         Print("API Response: ", response);
      }
      else
      {
         Print("API Error - Response Code: ", res);
         Print("API Error Response: ", response);
      }
   }
}