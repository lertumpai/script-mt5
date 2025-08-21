#property copyright "Lertumpai"
#property link      "https://www.mql5.com"

input string api_key = "S@rawit5171718";
input string base_url = "http://192.168.1.35:5000";
input string bulk_update_price_path = "/prices/bulk-update";
input string update_price_path      = "/prices/update";
input string iq_monitor_upsert_path = "/iq-monitor/upsert";

int timeout = 10000;

// ใส่ header ให้ครบ อ่านง่าย และไม่ใส่ Content-Length (MT5 จะใส่ให้เอง)
string CommonHeaders()
{
   string h = 
      "Content-Type: application/json\r\n"
      "Cookie: api_key=" + api_key + "\r\n";
   return h;
}

// Helper: ทำ JSON -> char[] (UTF-8)
void JsonToBytes(const string json, char &out[])
{
   ArrayFree(out);
   // คืนค่าจำนวนตัวอักษร (รวม NUL) แต่เราจะลบทิ้ง
   int n = StringToCharArray(json, out, 0, WHOLE_ARRAY, CP_UTF8);
   if(n > 0) ArrayResize(out, n - 1); // ตัด NUL ทิ้ง
}

// -------- BULK UPDATE --------
void CallBulkUpdatePriceApi(string json_body)
{
   string api = base_url + bulk_update_price_path;

   string debug_body = StringLen(json_body) > 200 ? StringSubstr(json_body, 0, 200) + "..." : json_body;
   Print("Bulk POST Body: ", debug_body);

   char post[];
   JsonToBytes(json_body, post);

   char result[];
   string result_headers = "";
   ResetLastError();
   int res = WebRequest("POST", api, CommonHeaders(), timeout, post, result, result_headers);

   if(res == -1)
   {
      int err = GetLastError();
      PrintFormat("WebRequest failed (bulk). err=%d, headers=%s", err, result_headers);
      if(err == 4060)
         Print("URL not allowed. Add ", base_url, " (with port) to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
      return;
   }

   string response = CharArrayToString(result, 0, -1, CP_UTF8);
   PrintFormat("Bulk ResponseCode=%d, RespHeaders=%s", res, result_headers);

   if(res != 200 && res != 201)
   {
      Print("API Error - Response Code: ", res);
      Print("API Error Response: ", response);
      if(StringFind(response, "Prices array cannot be empty") != -1)
         Print("ERROR: Sent empty prices array. Check JSON format.");
      else if(StringFind(response, "Cannot process more than 1000 records") != -1)
         Print("ERROR: Too many records in batch. Reduce bulk_send_batch_size.");
      return;
   }

   // parse แบบเบา ๆ
   int pos = StringFind(response, "\"successful\":");
   if(pos != -1)
   {
      string temp = StringSubstr(response, pos + 13);
      int comma_pos = StringFind(temp, ",");
      if(comma_pos != -1)
      {
         string successful_count = StringSubstr(temp, 0, comma_pos);
         Print("Bulk update: ", successful_count, " records successful");
      }
   }
   else
   {
      Print("API Success but unexpected response format: ", response);
   }
}

// -------- SINGLE UPDATE --------
void CallPriceUpdateAPI(string symbol, double open, double high, double low, double close, string timeframe, string priceDateTime)
{
   string api = base_url + update_price_path;

   string json_body = StringFormat(
      "{\"symbol\":\"%s\",\"open\":%.5f,\"high\":%.5f,\"low\":%.5f,\"close\":%.5f,\"timeframe\":\"%s\",\"priceDateTime\":\"%s\"}",
      symbol, open, high, low, close, timeframe, priceDateTime
   );

   char post[];
   JsonToBytes(json_body, post);

   char result[];
   string result_headers = "";
   ResetLastError();
   int res = WebRequest("POST", api, CommonHeaders(), timeout, post, result, result_headers);

   if(res == -1)
   {
      int err = GetLastError();
      PrintFormat("WebRequest failed (single). err=%d, headers=%s", err, result_headers);
      if(err == 4060)
         Print("URL not allowed. Add ", base_url, " (with port) to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
      return;
   }

   string response = CharArrayToString(result, 0, -1, CP_UTF8);
   PrintFormat("Single ResponseCode=%d, RespHeaders=%s", res, result_headers);

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

// -------- IQ MONITOR UPSERT --------
void UpsertIqMonitor(string monitor_name, double amount, double score, double confidence, int consecutive_loss, string direction = "NONE")
{
   if(StringLen(monitor_name) == 0){ Print("ERROR: Monitor name cannot be empty"); return; }
   if(amount <= 0){ Print("ERROR: Amount must be greater than 0"); return; }
   if(confidence < 0 || confidence > 1){ Print("ERROR: Confidence must be between 0 and 1"); return; }
   if(consecutive_loss < 0){ Print("ERROR: Consecutive loss cannot be negative"); return; }
   if(direction != "PUT" && direction != "CALL" && direction != "NONE"){ Print("ERROR: Direction must be PUT, CALL, or NONE. Using NONE as default."); direction = "NONE"; }

   string monitor_json = StringFormat(
      "{\"name\":\"%s\",\"amount\":%.2f,\"score\":%.2f,\"confidence\":%.2f,\"consecutiveLoss\":%d,\"direction\":\"%s\"}",
      monitor_name, amount, score, confidence, consecutive_loss, direction
   );

   Print("Upserting IQ Monitor: ", monitor_name);
   Print("Payload: ", monitor_json);

   CallIqMonitorUpsertApi(monitor_json);
}

void CallIqMonitorUpsertApi(string json_body)
{
   string api = base_url + iq_monitor_upsert_path;

   Print("Calling IQ Monitor API: ", api);

   char post[];
   JsonToBytes(json_body, post);

   char result[];
   string result_headers = "";

   ResetLastError();
   int res = WebRequest("POST", api, CommonHeaders(), timeout, post, result, result_headers);

   if(res == -1)
   {
      int err = GetLastError();
      PrintFormat("WebRequest failed (monitor). err=%d, headers=%s", err, result_headers);
      if(err == 4060)
         Print("URL not allowed. Add ", base_url, " (with port) to Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
      return;
   }

   string response = CharArrayToString(result, 0, -1, CP_UTF8);
   PrintFormat("Monitor ResponseCode=%d, RespHeaders=%s", res, result_headers);

   if(res != 200 && res != 201)
   {
   
      Print("IQ Monitor API Error - Response Code: ", res);
      Print("API Error Response: ", response);
   }
   else
   {
      Print("IQ Monitor upsert successful - Response Code: ", res);
      Print("API Response: ", response);
   }
}
