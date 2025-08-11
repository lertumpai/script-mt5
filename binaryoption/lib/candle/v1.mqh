//---- Helper functions to get features
double CandleBody(int shift){ return iClose(_Symbol, PERIOD_M1, shift) - iOpen(_Symbol, PERIOD_M1, shift); }
double CandleRange(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - iLow(_Symbol, PERIOD_M1, shift); }
double UpperShadow(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - MathMax(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)); }
double LowerShadow(int shift){ return MathMin(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)) - iLow(_Symbol, PERIOD_M1, shift); }

void PrintPrice(int shift) {
   Print("Time[", iTime(_Symbol, PERIOD_M1, shift), "]","-> open: ", iOpen(_Symbol, PERIOD_M1, shift), ", high: ", iHigh(_Symbol, PERIOD_M1, shift), ", low: ", iLow(_Symbol, PERIOD_M1, shift), ", close: ", iClose(_Symbol, PERIOD_M1, shift));
}

string GetSystemName() {
   return "candle_v1";
}

double PredictSignal()
{
   Print(0);
   Print(1);
   Print(2);
   Print(3);
   
   double cb0 = CandleBody(0);
   double cr0 = CandleRange(0);
   double us0 = UpperShadow(0);
   double ls0 = LowerShadow(0);
   double oc_ratio = cb0 / (iOpen(_Symbol, PERIOD_M1, 0)+0.000001);
   double hl_ratio = cr0 / (iLow(_Symbol, PERIOD_M1, 0)+0.000001);

   double cb1 = CandleBody(1);
   double cr1 = CandleRange(1);
   double cb2 = CandleBody(2);
   double cr2 = CandleRange(2);
   double cb3 = CandleBody(3);
   double cr3 = CandleRange(3);

   double score = 0.0;

   // ====== Example Tree Rules from XGBoost ======
   // NOTE: #5I7- rule#45H6!2B!@% XGBoost
   if(cb0 < 0.00005)
   {
      if(cb1 > 0) score += 0.12;
      else score -= 0.08;
   }
   else
   {
      if(cr0 < 0.0003) score += 0.18;
      else score -= 0.1;
   }

   if(oc_ratio > 0.0) score += 0.06;
   else score -= 0.04;

   if(cb2 > 0 && cb3 > 0) score += 0.09;
   if(cb2 < 0 && cb3 < 0) score -= 0.09;
   // ====== End of Rules ======

   Print("Score: ", score);

   return score;
}