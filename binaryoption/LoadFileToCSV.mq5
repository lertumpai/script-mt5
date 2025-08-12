//+------------------------------------------------------------------+
//|              Export OHLC during Strategy Tester                  |
//+------------------------------------------------------------------+
#property strict

input string FileName = "tester_ohlc.csv";
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M1;
input bool Append = false; 

int handle;
bool header_written = false;

int OnInit()
{
   int mode = FILE_WRITE|FILE_CSV|FILE_ANSI;
   if(Append) mode = FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI;

   handle = FileOpen(FileName, mode, ",");
   if(handle == INVALID_HANDLE)
   {
      Print("❌ File open error: ", GetLastError());
      return(INIT_FAILED);
   }

   if(!Append)
   {
      FileWrite(handle, "priceDateTime","open","high","low","close");
      header_written = true;
   }

   return(INIT_SUCCEEDED);
}

void OnTick()
{
   int bar = 1;
   static datetime last_time = 0;
   datetime t = iTime(_Symbol, TimeFrame, bar);

   if(t == last_time) return;
   last_time = t;

   double o = iOpen(_Symbol, TimeFrame, bar);
   double h = iHigh(_Symbol, TimeFrame, bar);
   double l = iLow(_Symbol, TimeFrame, bar);
   double c = iClose(_Symbol, TimeFrame, bar);

   string timestamp = TimeToString(t, TIME_DATE|TIME_SECONDS);
   StringReplace(timestamp, " ", "T");
   StringReplace(timestamp, ".", "-");
   timestamp += ".000Z";
   
   FileWrite(handle, timestamp, DoubleToString(o, 5), DoubleToString(h, 5), DoubleToString(l, 5), DoubleToString(c, 5));
}

void OnDeinit(const int reason)
{
   if(handle != INVALID_HANDLE)
      FileClose(handle);
   Print("✅ Export finished: ", FileName);
}
