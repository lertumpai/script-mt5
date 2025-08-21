//============================================================
// candle_v1 - score + confidence (fixed)
//============================================================
namespace candle_v2_confidence
{
   // ---------- Small math helpers (ประกาศก่อนใช้งาน) ----------
   double Clamp(double x, double lo, double hi)
   {
      if(x < lo) return lo;
      if(x > hi) return hi;
      return x;
   }

   // ป้องกันหารศูนย์: ถ้า |den| <= eps คืน 0.0
   double SafeDiv(double num, double den, double eps=1e-12)
   {
      if(MathAbs(den) <= eps) return 0.0;
      return num/den;
   }

   // เครื่องหมาย: >0 -> +1, <0 -> -1, =0 -> 0
   int Sign(double x)
   {
      return (x > 0.0) ? 1 : ((x < 0.0) ? -1 : 0);
   }

   double Sigmoid(double x){ return 1.0 / (1.0 + MathExp(-x)); }

   // Breakeven win probability for binary options with payout r (e.g., 0.80)
   double RequiredWinProb(double payout){ return 1.0 / (1.0 + MathMax(0.0, payout)); }

   // ตัดสินใจเทรดจาก confidence กับ payout; buffer คือ margin เผื่อความปลอดภัย
   bool ShouldTrade(double confidence, double payout, double buffer=0.0)
   {
      double thr = RequiredWinProb(payout) + MathMax(0.0, buffer);
      return (confidence >= thr);
   }

   // ---------- Helper functions to get features ----------
   double CandleBody(int shift){ return iClose(_Symbol, PERIOD_M1, shift) - iOpen(_Symbol, PERIOD_M1, shift); }
   double CandleRange(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - iLow(_Symbol, PERIOD_M1, shift); }
   double UpperShadow(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - MathMax(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)); }
   double LowerShadow(int shift){ return MathMin(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)) - iLow(_Symbol, PERIOD_M1, shift); }

   // ---------- Raw score (ตัวอย่างกฎ) ----------
   double PredictSignal()
   {
      double cb0 = CandleBody(0);
      double cr0 = CandleRange(0);
      double us0 = UpperShadow(0);
      double ls0 = LowerShadow(0);
      double oc_ratio = SafeDiv(cb0, iOpen(_Symbol, PERIOD_M1, 0)+1e-6, 1e-12);
      double hl_ratio = SafeDiv(cr0, iLow(_Symbol, PERIOD_M1, 0)+1e-6,  1e-12);

      double cb1 = CandleBody(1);
      double cr1 = CandleRange(1);
      double cb2 = CandleBody(2);
      double cr2 = CandleRange(2);
      double cb3 = CandleBody(3);
      double cr3 = CandleRange(3);

      double score = 0.0;

      // ====== Example Tree Rules from XGBoost ======
      if(cb0 < 0.00005)
      {
         if(cb1 > 0) score += 0.12;
         else score -= 0.08;
      }
      else
      {
         if(cr0 < 0.0003) score += 0.18;
         else score -= 0.10;
      }

      if(oc_ratio > 0.0) score += 0.06;
      else               score -= 0.04;

      if(cb2 > 0 && cb3 > 0) score += 0.09;
      if(cb2 < 0 && cb3 < 0) score -= 0.09;
      // ====== End of Rules ======

      return score;
   }

   // ---------- Context struct ----------
   struct BarContext {
      double cb0, cr0, us0, ls0;
      double cb1, cr1, cb2, cr2, cb3, cr3;
      double body_frac0, ufrac0, lfrac0;
      double mom2, mom3;
      bool   rex, rin;
      double rel_range;
   };

   // เติมข้อมูลให้ BarContext จากแท่งปัจจุบัน
   void LoadBarContext(BarContext &C)
   {
      const double eps = 1e-7;

      C.cb0 = CandleBody(0);  C.cr0 = CandleRange(0);
      C.us0 = UpperShadow(0); C.ls0 = LowerShadow(0);

      C.cb1 = CandleBody(1);  C.cr1 = CandleRange(1);
      C.cb2 = CandleBody(2);  C.cr2 = CandleRange(2);
      C.cb3 = CandleBody(3);  C.cr3 = CandleRange(3);

      double mean_r = (C.cr1 + C.cr2 + C.cr3) / 3.0;
      if(mean_r < eps) mean_r = eps;

      C.body_frac0 = (C.cr0 > eps) ? (MathAbs(C.cb0)/C.cr0) : 0.0;
      C.ufrac0     = (C.cr0 > eps) ? (C.us0 / C.cr0)        : 0.0;
      C.lfrac0     = (C.cr0 > eps) ? (C.ls0 / C.cr0)        : 0.0;

      C.mom2 = SafeDiv(C.cb1 + C.cb2, mean_r, eps);
      C.mom3 = SafeDiv(C.cb1 + C.cb2 + C.cb3, 3.0*mean_r, eps);

      C.rex  = (C.cr0 > C.cr1 && C.cr1 > C.cr2);
      C.rin  = (C.cr0 < C.cr1 && C.cr1 < C.cr2);

      C.rel_range = SafeDiv(C.cr0, mean_r, eps);
   }

   // ---------- confidence ----------
   double PredictConfidence(double score, const BarContext &C)
   {
      // 1) Base confidence จาก |score|
      const double k = 3.0;
      const double m = 0.35;
      double base = Sigmoid(k * (MathAbs(score) - m)); // 0..1

      // 2) Agreement votes
      int dir = (score >= 0.0) ? +1 : -1;
      int votes = 0, total = 0;

      // recent momentum alignment
      total += 2;
      if(Sign(C.mom2) == dir) votes++;
      if(Sign(C.mom3) == dir) votes++;

      // body sign agreement with previous bar
      total += 1;
      if(Sign(C.cb0) == dir && Sign(C.cb1) == dir) votes++;

      // regime & size
      total += 2;
      if(C.rex && Sign(C.cb0) == dir) votes++;
      if(C.rel_range >= 1.3 && Sign(C.cb0) == dir) votes++;

      // rejection/pin support
      total += 2;
      if(dir > 0 && C.lfrac0 >= 0.45 && C.ufrac0 <= 0.25) votes++;
      if(dir < 0 && C.ufrac0 >= 0.45 && C.lfrac0 <= 0.25) votes++;

      double agreement = (total > 0) ? (double(votes)/double(total)) : 0.5; // 0..1

      // 3) Combine base + agreement
      double conf = 0.6*base + 0.4*agreement;

      // 4) Dampeners
      if(C.rel_range <= 0.7)  conf *= 0.90;   // tiny bar
      if(C.body_frac0 < 0.20) conf *= 0.92;   // indecision-type
      if(C.rin)               conf *= 0.94;   // range contraction

      // Bounds & NaN guard
      conf = Clamp(conf, 0.0, 1.0);
      if(!MathIsValidNumber(conf)) conf = 0.5;

      return conf;
   }

   // ---------- All-in-one ----------
   enum Direction { PUT = -1, CALL = +1 };

   struct Decision {
      Direction dir;
      double    score;        // raw score
      double    confidence;   // 0..1
   };

   Decision PredictSignalWithConfidence()
   {
      Decision d; d.dir = CALL; d.score = 0.0; d.confidence = 0.5;

      // 1) score
      double score = PredictSignal();
      d.score = score;
      d.dir   = (score >= 0.0) ? CALL : PUT;

      // 2) confidence
      BarContext C; LoadBarContext(C);
      d.confidence = PredictConfidence(score, C);

      return d;
   }
   
   double Confidence(double score) {
      BarContext C; LoadBarContext(C);
      return PredictConfidence(score, C);
   }

   string GetSystemName()
   {
      return "candle_v2_confidence";
   }
}
