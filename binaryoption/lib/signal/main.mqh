#include "./candle_v1.mqh"
#include "./candle_v2.mqh"

enum SignalModelEnum {
   Candle_v1 = 0,
   Candle_v2 = 1
};

input SignalModelEnum SignalModel = Candle_v1;

double PredictSignal() {
   double score = 0;
   switch (SignalModel) {
      case Candle_v1: score = candle_v1::PredictSignal();
      case Candle_v2: score = candle_v2::PredictSignal();
   }
   
   Print("Score: ", score);
   
   return score;
}

string GetSystemName() {
   switch (SignalModel) {
      case Candle_v1: return candle_v1::GetSystemName();
      case Candle_v2: return candle_v2::GetSystemName();
   }
   
   return "missing signal";
}