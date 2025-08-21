#include "./candle_v1.mqh"
#include "./candle_v2.mqh"

enum SignalModelEnum {
   Candle_v1 = 0,
   Candle_v2 = 1
};

input SignalModelEnum SignalModel = Candle_v1;

double predicted_score = 0;
double predicted_confidence = 0;
string predicted_direction = "NONE";

void PredictSignal() {
   switch (SignalModel) {
      case Candle_v1: predicted_score = candle_v1::PredictSignal();
      case Candle_v2: predicted_score = candle_v2::PredictSignal();
   }
   
   if (predicted_score >= 0) {
      predicted_direction = "CALL";
   } else {
      predicted_direction = "PUT";
   }
   
   Print("score=", predicted_score, ", direction=", predicted_direction);
}

string GetSystemName() {
   switch (SignalModel) {
      case Candle_v1: return candle_v1::GetSystemName();
      case Candle_v2: return candle_v2::GetSystemName();
   }
   
   return "missing signal";
}