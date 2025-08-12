//--- Compute current broker/server offset to UTC in seconds.
   //    Works live and in Strategy Tester. Positive = server ahead of UTC.
   int ServerUtcOffsetSeconds()
   {
      datetime srv = TimeTradeServer();
      if(srv == 0) // fallback (e.g., Strategy Tester or no trade server)
         srv = TimeCurrent();

      datetime utc_now = TimeGMT();
      // Difference at "now" approximates server timezone offset (incl. DST).
      int diff = (int)(srv - utc_now);
      return diff;
   }

   //--- Convert a server-time datetime to UTC datetime
   datetime ToUTC(datetime server_dt)
   {
      return (server_dt - ServerUtcOffsetSeconds());
   }

   //--- Format a UTC datetime as ISO-8601 "YYYY-MM-DDTHH:MM:SSZ"
   string FormatISO8601(datetime utc_dt)
   {
      MqlDateTime s;
      TimeToStruct(utc_dt, s);
      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          s.year, s.mon, s.day, s.hour, s.min, s.sec);
   }

   //--- 1) format date to UTC (input is server time), returns ISO-8601
   string FormatUTC(datetime server_dt)
   {
      return FormatISO8601(ToUTC(server_dt));
   }

   //--- 2) get nowDateTime() -> return now UTC format (ISO-8601)
   string NowDateTime()
   {
      // We obtain "server now" and convert to UTC for consistency with server-based timestamps.
      datetime server_now = TimeTradeServer();
      if(server_now == 0) server_now = TimeCurrent();
      return FormatUTC(server_now);
   }

   //--- 3) get nowDateTimeMinute() -> UTC only Y-M-D H:M (no seconds)
   //     Returns "YYYY-MM-DDTHH:MMZ"
   string NowDateTimeMinute()
   {
      datetime server_now = TimeTradeServer();
      if(server_now == 0) server_now = TimeCurrent();

      datetime utc_now = ToUTC(server_now);
      MqlDateTime s;
      TimeToStruct(utc_now, s);
      return StringFormat("%04d-%02d-%02dT%02d:%02dZ",
                          s.year, s.mon, s.day, s.hour, s.min);
   }