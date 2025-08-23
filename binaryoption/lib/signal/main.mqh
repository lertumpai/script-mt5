#include "./type.mqh"
#include "./candle_v1.mqh"
#include "./candle_v2.mqh"
#include "./candle_v2_confidence.mqh"

enum SignalModelEnum {
   Candle_v1 = 0,
   Candle_v2 = 1,
   Candle_v2_confidence = 2
};

input SignalModelEnum SignalModel = Candle_v1;
input bool ConfidenceMode = false;
input int ConfidenceModeAfterLoss = 0;

Decision PredictSignal(int _consecutiveLoss) {
   Decision decision;
   bool shouldAction = false;
   bool enableConfidenceAfterLoss = false;

   switch (SignalModel) {
      case Candle_v1: {
         decision.score = candle_v1::PredictSignal();
         decision.confidence = 0;
         break;
      }
      case Candle_v2: {
         decision.score = candle_v2::PredictSignal();
         decision.confidence = 0;
         break;
      }
      case Candle_v2_confidence: {
         decision.score = candle_v2_confidence::PredictSignal();
         decision.confidence = candle_v2_confidence::Confidence(decision.score);
         shouldAction = candle_v2_confidence::ShouldAction(decision.confidence);
         enableConfidenceAfterLoss = _consecutiveLoss >= ConfidenceModeAfterLoss;
         break;
      }
   }
   
   if (ConfidenceMode && enableConfidenceAfterLoss && !shouldAction) {
      decision.direction = "NONE";
   } else if (decision.score >= 0) {
      decision.direction = "CALL";
   } else {
      decision.direction = "PUT";
   }
   
   Print("score=", decision.score, ", direction=", decision.direction, ", confidence=", decision.confidence);
   
   return decision;
}

string GetSystemName() {
   switch (SignalModel) {
      case Candle_v1: return candle_v1::GetSystemName();
      case Candle_v2: return candle_v2::GetSystemName();
      case Candle_v2_confidence: return candle_v2_confidence::GetSystemName();
   }
   
   return "missing signal";
}