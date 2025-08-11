//---- Helper functions (yours)
double CandleBody(int shift){ return iClose(_Symbol, PERIOD_M1, shift) - iOpen(_Symbol, PERIOD_M1, shift); }
double CandleRange(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - iLow(_Symbol, PERIOD_M1, shift); }
double UpperShadow(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - MathMax(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)); }
double LowerShadow(int shift){ return MathMin(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)) - iLow(_Symbol, PERIOD_M1, shift); }

void PrintPrice(int shift) {
   Print("Time[", iTime(_Symbol, PERIOD_M1, shift), "]","-> open: ", iOpen(_Symbol, PERIOD_M1, shift), ", high: ", iHigh(_Symbol, PERIOD_M1, shift), ", low: ", iLow(_Symbol, PERIOD_M1, shift), ", close: ", iClose(_Symbol, PERIOD_M1, shift));
}

//---- Logistic-style score learned from your CSV (ALL-DAY model)
// Decision boundary: score >= 0 -> CALL, else PUT
double PredictSignal()
{
   Print(0);
   Print(1);
   Print(2);
   Print(3);

   // Current + lagged features
   double body0 = CandleBody(0);
   double range0 = CandleRange(0);
   double ushadow0 = UpperShadow(0);
   double lshadow0 = LowerShadow(0);

   double body1 = CandleBody(1);
   double range1 = CandleRange(1);
   double ushadow1 = UpperShadow(1);
   double lshadow1 = LowerShadow(1);

   double body2 = CandleBody(2);
   double range2 = CandleRange(2);
   double ushadow2 = UpperShadow(2);
   double lshadow2 = LowerShadow(2);

   double body3 = CandleBody(3);
   double range3 = CandleRange(3);
   double ushadow3 = UpperShadow(3);
   double lshadow3 = LowerShadow(3);

   // Rolling mean of body over last 3 (0..2)
   double body_mean3 = (body0 + body1 + body2) / 3.0;

   // ---------- Learned raw weights (from sparse logistic regression) ----------
   // Only non-zero weights are included to keep it compact.
   // score = sum(w_i * feature_i) + intercept
   double score = 0.0;
   score += ( 606.3721605250722) * ushadow0;
   score += ( 519.5669178707532) * ushadow2;
   score += ( 437.8406794376436) * range3;
   score += (-698.9924783838044) * ushadow3;
   score += (-604.4801689295290) * body_mean3;
   score += (-237.3787573781613) * body0;
   score += (-132.0553599841477) * body3;
   score += (-123.8348964197375) * lshadow2;
   score += ( -59.1023857153487) * lshadow0;
   score += ( -40.0626439051844) * range1;

   // Intercept
   score += (-0.17448617656708537);

   // Optional: sanity guard when data is missing (e.g., first few bars)
   if(!MathIsValidNumber(score))
      return 0; // skip

   // Debug
   // PrintFormat("LR score=%.6f  ush0=%.5e ush2=%.5e rng3=%.5e ush3=%.5e bmean3=%.5e b0=%.5e b3=%.5e lsh2=%.5e lsh0=%.5e rng1=%.5e",
   //             score, ushadow0, ushadow2, range3, ushadow3, body_mean3, body0, body3, lshadow2, lshadow0, range1);

   return score;
}
