// ---------- Helpers (same as yours) ----------
double CandleBody(int shift){ return iClose(_Symbol, PERIOD_M1, shift) - iOpen(_Symbol, PERIOD_M1, shift); }
double CandleRange(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - iLow(_Symbol, PERIOD_M1, shift); }
double UpperShadow(int shift){ return iHigh(_Symbol, PERIOD_M1, shift) - MathMax(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)); }
double LowerShadow(int shift){ return MathMin(iClose(_Symbol, PERIOD_M1, shift), iOpen(_Symbol, PERIOD_M1, shift)) - iLow(_Symbol, PERIOD_M1, shift); }

// ---------- Balanced logistic model (trained from your CSV) ----------
namespace BalancedModel
{
   // Standardization parameters for features:
   // [b0,r0,u0,l0, b1,r1,u1,l1, b2,r2,u2,l2, b3,r3,u3,l3, bmean3]
   double MEAN[17] = {
      -0.000000612922,  0.000170998240,  0.000061800278, -0.000109156949,
      -0.000000620597,  0.000170999553,  0.000061803542, -0.000109159501,
      -0.000000596336,  0.000170997223,  0.000061803205, -0.000109156470,
      -0.000000582483,  0.000170997189,  0.000061803372, -0.000109156640,
      -0.000000609949
   };
   double STD[17] = {
      0.000058938199, 0.000134703027, 0.000058436971, 0.000058434694,
      0.000058938293, 0.000134702767, 0.000058436975, 0.000058434696,
      0.000058938314, 0.000134703402, 0.000058436987, 0.000058434701,
      0.000058938350, 0.000134703259, 0.000058436976, 0.000058434697,
      0.000047792192
   };

   // Balanced weights + intercept; threshold recenters to avoid CALL/PUT bias
   double W[17] = {
      -0.005020932915, -0.007475491542,  0.001175139038, -0.008814638164,
      -0.000968189023, -0.000649877108, -0.000562849616, -0.001900755206,
       0.001880537318, -0.000619224349,  0.001230191338, -0.000974418850,
       0.005793204129,  0.000246422750,  0.001167394025, -0.000239773896,
      -0.001688612756
   };
   double INTERCEPT = 0.000009887468;
   double THRESHOLD = 0.502041067964;   // ≈ median p to de-bias side selection

   // Candle-awareness (you can tune per symbol)
   double DOJI_BODY_FRAC   = 0.20;      // |body0| < 20% of range0 => weak info
   double MIN_RANGE_POINTS = 0.00005;   // micro-range filter (e.g., ~0.5 pip on EURUSD)

   // Optional abstain band; set 0 to disable abstain behavior here
   double CONF_BAND = 0.020;

   double Sigmoid(double z)
   {
      if(z > 50)  return 1.0;
      if(z < -50) return 0.0;
      return 1.0 / (1.0 + MathExp(-z));
   }

   // Internal: probability of CALL
   double PredictProb_()
   {
      if(Bars(_Symbol, PERIOD_M1) < 10) return 0.5;

      double b0 = CandleBody(0);
      double r0 = CandleRange(0);
      double u0 = UpperShadow(0);
      double l0 = LowerShadow(0);

      double b1 = CandleBody(1);
      double r1 = CandleRange(1);
      double u1 = UpperShadow(1);
      double l1 = LowerShadow(1);

      double b2 = CandleBody(2);
      double r2 = CandleRange(2);
      double u2 = UpperShadow(2);
      double l2 = LowerShadow(2);

      double b3 = CandleBody(3);
      double r3 = CandleRange(3);
      double u3 = UpperShadow(3);
      double l3 = LowerShadow(3);

      double bmean3 = (b0 + b1 + b2) / 3.0;

      // Candle-awareness filters (skip indecision / ultra-low range)
      if(r0 < MIN_RANGE_POINTS) return 0.5;
      if(MathAbs(b0) < DOJI_BODY_FRAC * r0) return 0.5;

      double X[17] = { b0,r0,u0,l0, b1,r1,u1,l1, b2,r2,u2,l2, b3,r3,u3,l3, bmean3 };

      double z = INTERCEPT;
      for(int i=0;i<17;i++)
      {
         double xi = (X[i] - MEAN[i]) / (STD[i] + 1e-12);
         z += W[i] * xi;
      }
      return Sigmoid(z);
   }
}

// ---------------- Public API (no parameters) ----------------
//
// PredictSignal():
//   returns a "score" centered at 0:
//     score >= 0  => CALL
//     score <  0  => PUT
//   If you want to enforce an abstain band in your EA, check |score| < CONF_BAND.
//
double PredictSignal()
{
   double p = BalancedModel::PredictProb_();
   // map to zero-centered score around the de-bias threshold
   double score = p - BalancedModel::THRESHOLD;

   // Optional local abstain (kept minimal so signature matches your old call)
   // If you prefer no abstain here, comment the next 3 lines and handle it in EA.
   if(MathAbs(score) < BalancedModel::CONF_BAND)
      return 0.0; // neutral/skip signal region (score ~ 0)

   return score;
}

// Convenience helper (optional): direct direction with no params.
//  1 = CALL, -1 = PUT, 0 = SKIP/neutral
int PredictDirection()
{
   double s = PredictSignal();
   if(s > 0.0)  return 1;
   if(s < 0.0)  return -1;
   return 0;
}

void PrintPrice(int shift) {
   Print("Time[", iTime(_Symbol, PERIOD_M1, shift), "]","-> open: ", iOpen(_Symbol, PERIOD_M1, shift), ", high: ", iHigh(_Symbol, PERIOD_M1, shift), ", low: ", iLow(_Symbol, PERIOD_M1, shift), ", close: ", iClose(_Symbol, PERIOD_M1, shift));
}

string GetSystemName() {
   return "candle_v2";
}