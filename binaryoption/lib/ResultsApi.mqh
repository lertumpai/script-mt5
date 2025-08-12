//+------------------------------------------------------------------+
//| ResultsApi.mqh                                                   |
//| Helper for calling NestJS Results API (upsert daily stats)       |
//| Requires adding the base URL to:                                 |
//| Tools -> Options -> Expert Advisors -> Allow WebRequest for URL  |
//+------------------------------------------------------------------+
#property strict

class CResultsApi
{
private:
   string   m_baseUrl;
   int      m_timeoutMs;
   string   m_lastResponse;
   string   m_lastError;
   int      m_lastStatus;

   bool HttpPost(const string path, const string jsonPayload)
   {
      string url = m_baseUrl + path;

      char   post_body[];
      StringToCharArray(jsonPayload, post_body, 0, WHOLE_ARRAY, CP_UTF8);

      string headers = "Content-Type: application/json\r\n";

      char   response[];
      string response_headers;

      int result = WebRequest(
         "POST",
         url,
         headers,
         m_timeoutMs,
         post_body,
         ArraySize(post_body),
         response,
         response_headers
      );

      m_lastResponse = CharArrayToString(response, 0, -1, CP_UTF8);
      m_lastStatus   = result;
      m_lastError    = "";

      if(result == -1)
      {
         m_lastError = "WebRequest failed. Ensure URL is allowed in terminal options.";
         return false;
      }

      // For REST, positive result is HTTP status code. Consider 2xx as success
      if(result >= 200 && result < 300)
         return true;

      // Non-2xx
      m_lastError = StringFormat("HTTP %d: %s", result, m_lastResponse);
      return false;
   }

   static string IntField(const string name, const int value)
   {
      return StringFormat("\"%s\":%d", name, value);
   }

   static string StrField(const string name, const string value)
   {
      // NOTE: minimal escaping (replace backslash and quotes)
      string v = value;
      StringReplace(v, "\\", "\\\\");
      StringReplace(v, "\"", "\\\"");
      return StringFormat("\"%s\":\"%s\"", name, v);
   }

public:
   CResultsApi(): m_baseUrl("http://localhost:3000"), m_timeoutMs(5000), m_lastResponse(""), m_lastError(""), m_lastStatus(0) {}

   void SetBaseUrl(const string baseUrl)
   {
      m_baseUrl = baseUrl;
   }

   void SetTimeoutMs(const int timeoutMs)
   {
      m_timeoutMs = timeoutMs;
   }

   string LastResponse() const { return m_lastResponse; }
   string LastError() const { return m_lastError; }
   int    LastStatus() const { return m_lastStatus; }

   // Upsert a daily result by date+account
   // date: YYYY-MM-DD
   bool Upsert(
      const string date,
      const string account,
      const int    win,
      const int    loss,
      const int    tie,
      const int    maxConsecutiveWin,
      const int    maxConsecutiveLoss,
      const int    consecutiveWin,
      const int    consecutiveLoss
   )
   {
      string json = "{"+
         StrField("date", date)+","+
         StrField("account", account)+","+
         IntField("win", win)+","+
         IntField("loss", loss)+","+
         IntField("tie", tie)+","+
         IntField("maxConsecutiveWin", maxConsecutiveWin)+","+
         IntField("maxConsecutiveLoss", maxConsecutiveLoss)+","+
         IntField("consecutiveWin", consecutiveWin)+","+
         IntField("consecutiveLoss", consecutiveLoss)+
      "}";

      return HttpPost("/results/upsert", json);
   }
};

//+------------------------------------------------------------------+
//| Example usage                                                    |
//|                                                                  |
//| CResultsApi api;                                                 |
//| api.SetBaseUrl("http://localhost:3000");                         |
//| bool ok = api.Upsert("2025-08-12","demo-1220581411",1,0,0,1,0,1,0);|
//| if(!ok) Print("Upsert failed: ", api.LastStatus(), " ", api.LastError());|
//| else    Print("Upsert ok: ", api.LastResponse());               |
//+------------------------------------------------------------------+


