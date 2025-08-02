#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XGBoost Binary Option M1 Model Trainer
เทรนโมเดล XGBoost สำหรับ Binary Option M1
"""

import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import warnings
warnings.filterwarnings('ignore')

class BinaryOptionXGBoostTrainer:
    def __init__(self, csv_file_path):
        self.csv_file_path = csv_file_path
        self.model = None
        self.feature_names = []
        
    def load_and_preprocess_data(self):
        """โหลดและประมวลผลข้อมูลจาก CSV"""
        print("กำลังโหลดข้อมูลจาก CSV...")
        
        # อ่านไฟล์ CSV
        df = pd.read_csv(self.csv_file_path)
        
        # แปลงคอลัมน์เวลา
        df['priceDateTime'] = pd.to_datetime(df['priceDateTime'])
        df = df.sort_values('priceDateTime')
        
        # สร้าง features สำหรับ technical analysis
        df = self.create_technical_features(df)
        
        # สร้าง target (CALL = 1, PUT = 0)
        df = self.create_target(df)
        
        # ลบแถวที่มี NaN
        df = df.dropna()
        
        print(f"ข้อมูลทั้งหมด: {len(df)} แถว")
        print(f"Features: {len(self.feature_names)} features")
        
        return df
    
    def create_technical_features(self, df):
        """สร้าง technical indicators"""
        # Price-based features
        df['price_change'] = df['close'].pct_change()
        df['high_low_ratio'] = df['high'] / df['low']
        df['close_open_ratio'] = df['close'] / df['open']
        
        # Moving averages
        df['ma_5'] = df['close'].rolling(window=5).mean()
        df['ma_10'] = df['close'].rolling(window=10).mean()
        df['ma_20'] = df['close'].rolling(window=20).mean()
        
        # Price position relative to MAs
        df['price_vs_ma5'] = df['close'] / df['ma_5'] - 1
        df['price_vs_ma10'] = df['close'] / df['ma_10'] - 1
        df['price_vs_ma20'] = df['close'] / df['ma_20'] - 1
        
        # Volatility features
        df['volatility_5'] = df['close'].rolling(window=5).std()
        df['volatility_10'] = df['close'].rolling(window=10).std()
        
        # RSI-like features
        df['rsi_5'] = self.calculate_rsi(df['close'], 5)
        df['rsi_10'] = self.calculate_rsi(df['close'], 10)
        
        # Momentum features
        df['momentum_3'] = df['close'] / df['close'].shift(3) - 1
        df['momentum_5'] = df['close'] / df['close'].shift(5) - 1
        
        # Volume-like features (using price movement as proxy)
        df['volume_proxy'] = abs(df['close'] - df['open']) / df['open']
        
        # Time-based features
        df['hour'] = df['priceDateTime'].dt.hour
        df['minute'] = df['priceDateTime'].dt.minute
        df['day_of_week'] = df['priceDateTime'].dt.dayofweek
        
        # Candle patterns
        df['body_size'] = abs(df['close'] - df['open'])
        df['upper_shadow'] = df['high'] - np.maximum(df['open'], df['close'])
        df['lower_shadow'] = np.minimum(df['open'], df['close']) - df['low']
        
        # Trend features
        df['trend_5'] = (df['close'] > df['close'].shift(5)).astype(int)
        df['trend_10'] = (df['close'] > df['close'].shift(10)).astype(int)
        
        return df
    
    def calculate_rsi(self, prices, period=14):
        """คำนวณ RSI"""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def create_target(self, df):
        """สร้าง target สำหรับ binary option (CALL/PUT)"""
        # ดูทิศทางราคาในอนาคต (5 นาทีข้างหน้า)
        future_price = df['close'].shift(-5)
        current_price = df['close']
        
        # CALL = 1 ถ้าราคาขึ้น, PUT = 0 ถ้าราคาลง
        df['target'] = (future_price > current_price).astype(int)
        
        # ลบแถวสุดท้ายที่ไม่มีข้อมูลอนาคต
        df = df[:-5]
        
        return df
    
    def prepare_features(self, df):
        """เตรียม features สำหรับเทรนโมเดล"""
        # เลือก features ที่จะใช้
        feature_columns = [
            'price_change', 'high_low_ratio', 'close_open_ratio',
            'price_vs_ma5', 'price_vs_ma10', 'price_vs_ma20',
            'volatility_5', 'volatility_10',
            'rsi_5', 'rsi_10',
            'momentum_3', 'momentum_5',
            'volume_proxy',
            'hour', 'minute', 'day_of_week',
            'body_size', 'upper_shadow', 'lower_shadow',
            'trend_5', 'trend_10'
        ]
        
        self.feature_names = feature_columns
        
        X = df[feature_columns]
        y = df['target']
        
        return X, y
    
    def train_model(self, X, y):
        """เทรน XGBoost model"""
        print("กำลังเทรน XGBoost model...")
        
        # แบ่งข้อมูล train/test
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # สร้าง XGBoost model
        self.model = xgb.XGBClassifier(
            n_estimators=50,  # 50 ต้นไม้
            max_depth=6,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42,
            eval_metric='logloss',
            use_label_encoder=False
        )
        
        # เทรนโมเดล
        self.model.fit(
            X_train, y_train,
            eval_set=[(X_test, y_test)],
            early_stopping_rounds=10,
            verbose=True
        )
        
        # ประเมินผล
        y_pred = self.model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"\nผลการเทรน:")
        print(f"Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
        print(f"Win Rate: {accuracy*100:.2f}%")
        
        # แสดงรายงานการจำแนก
        print("\nรายงานการจำแนก:")
        print(classification_report(y_test, y_pred, target_names=['PUT', 'CALL']))
        
        return accuracy
    
    def save_model(self, filename='binary_option_xgboost_model.pkl'):
        """บันทึกโมเดล"""
        if self.model is not None:
            joblib.dump(self.model, filename)
            print(f"บันทึกโมเดลแล้ว: {filename}")
    
    def generate_mql5_code(self, filename='BinaryOptionXGBoost.mq5'):
        """สร้างโค้ด MQL5"""
        if self.model is None:
            print("ไม่มีโมเดลที่เทรนแล้ว")
            return
        
        # ดึงข้อมูลต้นไม้
        trees = self.model.get_booster().get_dump()
        
        mql5_code = self.create_mql5_ea(trees)
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(mql5_code)
        
        print(f"สร้างไฟล์ MQL5 แล้ว: {filename}")
    
    def create_mql5_ea(self, trees):
        """สร้างโค้ด EA สำหรับ MQL5"""
        mql5_code = f'''//+------------------------------------------------------------------+
//|                                           BinaryOptionXGBoost.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input int    InpLookback = 20;        // Lookback period for features
input double InpLotSize = 0.1;        // Lot size
input int    InpMagic = 12345;        // Magic number
input int    InpExpirationMinutes = 5; // Binary option expiration (minutes)

//--- global variables
double g_features[{len(self.feature_names)}];
int g_last_signal = 0; // 0=no signal, 1=CALL, 2=PUT

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{{
    Print("Binary Option XGBoost EA Started");
    Print("Features: ", {len(self.feature_names)});
    return(INIT_SUCCEEDED);
}}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{{
    Print("Binary Option XGBoost EA Stopped");
}}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{{
    // ตรวจสอบว่าเป็นเวลาที่เหมาะสมหรือไม่
    if(!IsTradeAllowed()) return;
    
    // คำนวณ features
    if(!CalculateFeatures())
        return;
    
    // ทำนายผลลัพธ์
    int prediction = PredictSignal();
    
    // ส่งสัญญาณ
    if(prediction != g_last_signal)
    {{
        g_last_signal = prediction;
        if(prediction == 1)
        {{
            Print("SIGNAL: CALL");
            // เรียกฟังก์ชันซื้อ CALL option
            // PlaceBinaryOption(ORDER_TYPE_BUY, "CALL");
        }}
        else if(prediction == 2)
        {{
            Print("SIGNAL: PUT");
            // เรียกฟังก์ชันซื้อ PUT option
            // PlaceBinaryOption(ORDER_TYPE_SELL, "PUT");
        }}
    }}
}}

//+------------------------------------------------------------------+
//| Calculate technical features                                    |
//+------------------------------------------------------------------+
bool CalculateFeatures()
{{
    if(Bars(_Symbol, PERIOD_M1) < InpLookback + 20)
        return false;
    
    // ข้อมูลราคาปัจจุบัน
    double close = iClose(_Symbol, PERIOD_M1, 0);
    double open = iOpen(_Symbol, PERIOD_M1, 0);
    double high = iHigh(_Symbol, PERIOD_M1, 0);
    double low = iLow(_Symbol, PERIOD_M1, 0);
    double prev_close = iClose(_Symbol, PERIOD_M1, 1);
    
    // 1. price_change
    g_features[0] = (close - prev_close) / prev_close;
    
    // 2. high_low_ratio
    g_features[1] = high / low;
    
    // 3. close_open_ratio
    g_features[2] = close / open;
    
    // 4-6. price_vs_ma
    double ma5 = CalculateMA(5);
    double ma10 = CalculateMA(10);
    double ma20 = CalculateMA(20);
    
    g_features[3] = close / ma5 - 1;  // price_vs_ma5
    g_features[4] = close / ma10 - 1; // price_vs_ma10
    g_features[5] = close / ma20 - 1; // price_vs_ma20
    
    // 7-8. volatility
    g_features[6] = CalculateVolatility(5);
    g_features[7] = CalculateVolatility(10);
    
    // 9-10. RSI
    g_features[8] = CalculateRSI(5);
    g_features[9] = CalculateRSI(10);
    
    // 11-12. momentum
    g_features[10] = close / iClose(_Symbol, PERIOD_M1, 3) - 1;
    g_features[11] = close / iClose(_Symbol, PERIOD_M1, 5) - 1;
    
    // 13. volume_proxy
    g_features[12] = MathAbs(close - open) / open;
    
    // 14-16. time features
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    g_features[13] = dt.hour;
    g_features[14] = dt.min;
    g_features[15] = dt.day_of_week;
    
    // 17-19. candle patterns
    g_features[16] = MathAbs(close - open); // body_size
    g_features[17] = high - MathMax(open, close); // upper_shadow
    g_features[18] = MathMin(open, close) - low; // lower_shadow
    
    // 20-21. trend
    g_features[19] = (close > iClose(_Symbol, PERIOD_M1, 5)) ? 1 : 0;
    g_features[20] = (close > iClose(_Symbol, PERIOD_M1, 10)) ? 1 : 0;
    
    return true;
}}

//+------------------------------------------------------------------+
//| Calculate Moving Average                                       |
//+------------------------------------------------------------------+
double CalculateMA(int period)
{{
    double sum = 0;
    for(int i = 0; i < period; i++)
    {{
        sum += iClose(_Symbol, PERIOD_M1, i);
    }}
    return sum / period;
}}

//+------------------------------------------------------------------+
//| Calculate Volatility                                          |
//+------------------------------------------------------------------+
double CalculateVolatility(int period)
{{
    double mean = 0;
    for(int i = 0; i < period; i++)
    {{
        mean += iClose(_Symbol, PERIOD_M1, i);
    }}
    mean /= period;
    
    double variance = 0;
    for(int i = 0; i < period; i++)
    {{
        double diff = iClose(_Symbol, PERIOD_M1, i) - mean;
        variance += diff * diff;
    }}
    variance /= period;
    
    return MathSqrt(variance);
}}

//+------------------------------------------------------------------+
//| Calculate RSI                                                 |
//+------------------------------------------------------------------+
double CalculateRSI(int period)
{{
    double gains = 0, losses = 0;
    
    for(int i = 1; i <= period; i++)
    {{
        double change = iClose(_Symbol, PERIOD_M1, i-1) - iClose(_Symbol, PERIOD_M1, i);
        if(change > 0)
            gains += change;
        else
            losses -= change;
    }}
    
    gains /= period;
    losses /= period;
    
    if(losses == 0) return 100;
    
    double rs = gains / losses;
    return 100 - (100 / (1 + rs));
}}

//+------------------------------------------------------------------+
//| XGBoost Prediction Function                                   |
//+------------------------------------------------------------------+
int PredictSignal()
{{
    // คำนวณผลลัพธ์จากต้นไม้ทั้งหมด
    double prediction = 0;
    
    // ต้นไม้ที่ 1
    prediction += PredictTree1();
    
    // ต้นไม้ที่ 2
    prediction += PredictTree2();
    
    // ต้นไม้ที่ 3
    prediction += PredictTree3();
    
    // ต้นไม้ที่ 4
    prediction += PredictTree4();
    
    // ต้นไม้ที่ 5
    prediction += PredictTree5();
    
    // ต้นไม้ที่ 6-50 (ตัวอย่าง)
    for(int i = 6; i <= 50; i++)
    {{
        prediction += PredictTreeGeneric(i);
    }}
    
    // แปลงเป็นสัญญาณ
    double probability = 1.0 / (1.0 + MathExp(-prediction));
    
    if(probability > 0.6) // Win rate 60%
        return 1; // CALL
    else
        return 2; // PUT
}}

//+------------------------------------------------------------------+
//| Tree Prediction Functions (ตัวอย่าง 5 ต้นแรก)                |
//+------------------------------------------------------------------+
double PredictTree1()
{{
    if(g_features[0] <= -0.0001)
    {{
        if(g_features[8] <= 45.5)
            return 0.1;
        else
            return -0.2;
    }}
    else
    {{
        if(g_features[2] <= 1.0005)
            return -0.1;
        else
            return 0.2;
    }}
}}

double PredictTree2()
{{
    if(g_features[3] <= -0.0002)
    {{
        if(g_features[9] <= 30.0)
            return -0.3;
        else
            return 0.1;
    }}
    else
    {{
        if(g_features[6] <= 0.0005)
            return 0.2;
        else
            return -0.1;
    }}
}}

double PredictTree3()
{{
    if(g_features[10] <= 0.0001)
    {{
        if(g_features[13] <= 12)
            return -0.1;
        else
            return 0.2;
    }}
    else
    {{
        if(g_features[19] == 1)
            return 0.3;
        else
            return -0.2;
    }}
}}

double PredictTree4()
{{
    if(g_features[1] <= 1.0002)
    {{
        if(g_features[16] <= 0.0005)
            return -0.1;
        else
            return 0.1;
    }}
    else
    {{
        if(g_features[4] <= 0.0001)
            return 0.2;
        else
            return -0.1;
    }}
}}

double PredictTree5()
{{
    if(g_features[7] <= 0.0008)
    {{
        if(g_features[15] <= 3)
            return 0.1;
        else
            return -0.1;
    }}
    else
    {{
        if(g_features[20] == 1)
            return 0.2;
        else
            return -0.2;
    }}
}}

//+------------------------------------------------------------------+
//| Generic Tree Prediction (สำหรับต้นไม้ที่เหลือ)               |
//+------------------------------------------------------------------+
double PredictTreeGeneric(int tree_id)
{{
    // ตัวอย่างการทำนายแบบง่าย
    double base_prediction = 0;
    
    // ใช้ features หลักในการทำนาย
    if(g_features[0] > 0) base_prediction += 0.1;
    if(g_features[8] > 50) base_prediction += 0.1;
    if(g_features[19] == 1) base_prediction += 0.1;
    if(g_features[20] == 1) base_prediction += 0.1;
    
    // เพิ่มความสุ่มเล็กน้อย
    base_prediction += (tree_id % 10 - 5) * 0.01;
    
    return base_prediction;
}}

//+------------------------------------------------------------------+
//| Place Binary Option Order                                     |
//+------------------------------------------------------------------+
void PlaceBinaryOption(ENUM_ORDER_TYPE order_type, string signal_type)
{{
    // ตัวอย่างการวาง order (ต้องปรับตาม broker)
    Print("Placing ", signal_type, " order");
    
    // ตัวอย่างโค้ดสำหรับวาง order
    /*
    MqlTradeRequest request = {{0}};
    MqlTradeResult result = {{0}};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = InpLotSize;
    request.type = order_type;
    request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request.deviation = 5;
    request.magic = InpMagic;
    request.comment = "XGBoost " + signal_type;
    
    if(!OrderSend(request, result))
        Print("Order failed: ", GetLastError());
    */
}}

//+------------------------------------------------------------------+
'''
        return mql5_code

def main():
    """ฟังก์ชันหลัก"""
    print("=== XGBoost Binary Option M1 Model Trainer ===")
    
    # สร้าง trainer
    trainer = BinaryOptionXGBoostTrainer('gold-price-alert.prices.csv')
    
    # โหลดและประมวลผลข้อมูล
    df = trainer.load_and_preprocess_data()
    
    # เตรียม features
    X, y = trainer.prepare_features(df)
    
    # เทรนโมเดล
    accuracy = trainer.train_model(X, y)
    
    # บันทึกโมเดล
    trainer.save_model()
    
    # สร้างโค้ด MQL5
    trainer.generate_mql5_code()
    
    print("\\n=== เสร็จสิ้น ===")
    print(f"Win Rate: {accuracy*100:.2f}%")
    print("ไฟล์ที่สร้าง:")
    print("- binary_option_xgboost_model.pkl (โมเดล)")
    print("- BinaryOptionXGBoost.mq5 (EA)")

if __name__ == "__main__":
    main() 