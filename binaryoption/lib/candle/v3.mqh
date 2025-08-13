// ---------- Helpers (same as yours) ----------
double CandleBody(int shift){ return iClose(_Symbol, PERIOD_M1, shift) - iOpen(_Symbol, PERIOD_M1, shift); }
double CandleRange(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - iLow(_Symbol, PERIOD_M1, shift); }
double UpperShadow(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - MathMax(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)); }
double LowerShadow(int shift){ return MathMin(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)) - iLow(_Symbol, PERIOD_M1, shift); }

// ---------- Small helpers ----------
double Sign(double x) { return (x > 0.0) ? 1.0 : ((x < 0.0) ? -1.0 : 0.0); }
double Clamp(double x, double lo, double hi)
{
   if(x < lo) return lo;
   if(x > hi) return hi;
   return x;
}
double SafeDiv(double a, double b, double eps=1e-12) { return a / ( (MathAbs(b) < eps) ? ( (b>=0)? eps : -eps ) : b ); }

// ---------- Your candlestick primitives assumed present ----------
// double CandleBody(int shift);
// double CandleRange(int shift);
// double UpperShadow(int shift);
// double LowerShadow(int shift);

double PredictSignal()
{
   const double eps  = 1e-7;
   const bool   log_details = false; // set true to see PrintFormat logs

   // --- current forming bar (shift=0) per your original
   double cb0 = CandleBody(0);
   double cr0 = CandleRange(0);
   double us0 = UpperShadow(0);
   double ls0 = LowerShadow(0);

   // scale-invariant helpers
   double oc_ratio   = SafeDiv(cb0, iOpen(_Symbol, PERIOD_M1, 0) + eps, eps);
   double hl_ratio   = SafeDiv(cr0, iLow(_Symbol,  PERIOD_M1, 0) + eps, eps);
   double body_frac0 = (cr0 > eps) ? (MathAbs(cb0) / cr0) : 0.0;
   double ufrac0     = (cr0 > eps) ? (us0 / cr0)         : 0.0;
   double lfrac0     = (cr0 > eps) ? (ls0 / cr0)         : 0.0;

   // --- recent history (context)
   double cb1 = CandleBody(1);
   double cr1 = CandleRange(1);
   double cb2 = CandleBody(2);
   double cr2 = CandleRange(2);
   double cb3 = CandleBody(3);
   double cr3 = CandleRange(3);

   double mean_r = (cr1 + cr2 + cr3) / 3.0;
   if(mean_r < eps) mean_r = eps;

   double mom2 = SafeDiv(cb1 + cb2, mean_r, eps);                 // short momentum (2 bars)
   double mom3 = SafeDiv(cb1 + cb2 + cb3, 3.0*mean_r, eps);       // broader momentum (3 bars)
   bool   rex  = (cr0 > cr1 && cr1 > cr2);                         // range expansion flag
   bool   rin  = (cr0 < cr1 && cr1 < cr2);                         // range contraction flag

   double score = 0.0;

   // ============================================================
   // 1) Micro-body vs range (indecision vs impulse)
   if(body_frac0 < 0.20)                 score += 0.10 * Sign(mom2);   // indecision → follow recent bias
   else if(body_frac0 >= 0.60)           score += 0.14 * Sign(cb0);    // impulsive body → continuation
   else                                  score += 0.04 * Sign(mom3);   // middling → slight trend follow

   // 2) Shadow rejection (pin bar style)
   if(lfrac0 >= 0.45 && ufrac0 <= 0.25)  score += 0.12;                // hammer-ish → bullish tilt
   if(ufrac0 >= 0.45 && lfrac0 <= 0.25)  score -= 0.12;                // shooting-star-ish → bearish tilt

   // 3) Current body sign + recent agreement
   if(cb0 > 0 && cb1 > 0)                score += 0.08;                // 2× green
   if(cb0 < 0 && cb1 < 0)                score -= 0.08;                // 2× red
   if(cb2 > 0 && cb3 > 0)                score += 0.05;                // deeper context
   if(cb2 < 0 && cb3 < 0)                score -= 0.05;

   // 4) Range regime
   if(rex)                                score += 0.07 * Sign(cb0);    // expansion: continuation
   if(rin)                                score -= 0.05 * Sign(cb0);    // contraction: slight fade

   // 5) Relative size vs recent volatility
   double rel_range = SafeDiv(cr0, mean_r, eps);                       // >1 bigger than recent typical
   if(rel_range >= 1.3)                   score += 0.06 * Sign(cb0);    // breakout-sized bar
   else if(rel_range <= 0.7)              score -= 0.03 * Sign(cb0);    // tiny bar → fade a bit

   // 6) Your original ratio cues (kept, but moderated)
   if(oc_ratio > 0.0)                     score += 0.05; else score -= 0.04;
   if(hl_ratio > 0.0)                     score += 0.02;

   // 7) Safety guardrails
   if(!MathIsValidNumber(score))          score = 0.0;
   score = Clamp(score, -1.5, 1.5);

   return score; // caller: (score >= 0) ? CALL : PUT
}

void PrintPrice(int shift) {
   Print("Time[", iTime(_Symbol, PERIOD_M1, shift), "]","-> open: ", iOpen(_Symbol, PERIOD_M1, shift), ", high: ", iHigh(_Symbol, PERIOD_M1, shift), ", low: ", iLow(_Symbol, PERIOD_M1, shift), ", close: ", iClose(_Symbol, PERIOD_M1, shift));
}

string GetSystemName() {
   return "candle_v3";
}