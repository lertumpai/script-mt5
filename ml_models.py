import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler
import joblib
import warnings
warnings.filterwarnings('ignore')

class BinaryOptionMLModels:
    def __init__(self, csv_file='ohlc.csv'):
        self.csv_file = csv_file
        self.data = None
        self.X = None
        self.y = None
        self.scaler = StandardScaler()
        self.models = {}
        self.results = {}
        
    def load_and_preprocess_data(self):
        """โหลดและ preprocess ข้อมูล OHLC"""
        print("กำลังโหลดข้อมูล...")
        self.data = pd.read_csv(self.csv_file)
        self.data['priceDateTime'] = pd.to_datetime(self.data['priceDateTime'])
        self.data = self.data.sort_values('priceDateTime').reset_index(drop=True)
        
        print(f"ข้อมูลทั้งหมด: {len(self.data)} แถว")
        print(f"ช่วงเวลา: {self.data['priceDateTime'].min()} ถึง {self.data['priceDateTime'].max()}")
        
        # สร้าง features
        self.create_features()
        
        # สร้าง target สำหรับ binary option (price จะขึ้นหรือลงใน 5 นาทีข้างหน้า)
        self.create_target()
        
        # ลบแถวที่มี NaN
        self.data = self.data.dropna()
        print(f"ข้อมูลหลังลบ NaN: {len(self.data)} แถว")
        
    def create_features(self):
        """สร้าง technical indicators และ features"""
        # Price changes
        self.data['price_change'] = self.data['close'].pct_change()
        self.data['high_low_ratio'] = self.data['high'] / self.data['low']
        self.data['open_close_ratio'] = self.data['open'] / self.data['close']
        
        # Moving averages
        for period in [5, 10, 20, 50]:
            self.data[f'ma_{period}'] = self.data['close'].rolling(period).mean()
            self.data[f'ma_{period}_ratio'] = self.data['close'] / self.data[f'ma_{period}']
        
        # RSI
        delta = self.data['close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        self.data['rsi'] = 100 - (100 / (1 + rs))
        
        # Bollinger Bands
        self.data['bb_middle'] = self.data['close'].rolling(20).mean()
        bb_std = self.data['close'].rolling(20).std()
        self.data['bb_upper'] = self.data['bb_middle'] + (bb_std * 2)
        self.data['bb_lower'] = self.data['bb_middle'] - (bb_std * 2)
        self.data['bb_position'] = (self.data['close'] - self.data['bb_lower']) / (self.data['bb_upper'] - self.data['bb_lower'])
        
        # Volume-like features (using price volatility as proxy)
        self.data['volatility'] = self.data['close'].rolling(20).std()
        self.data['volatility_ratio'] = self.data['volatility'] / self.data['close']
        
        # Momentum indicators
        self.data['momentum_5'] = self.data['close'] / self.data['close'].shift(5) - 1
        self.data['momentum_10'] = self.data['close'] / self.data['close'].shift(10) - 1
        
        # Support/Resistance levels
        self.data['support'] = self.data['low'].rolling(20).min()
        self.data['resistance'] = self.data['high'].rolling(20).max()
        self.data['support_distance'] = (self.data['close'] - self.data['support']) / self.data['close']
        self.data['resistance_distance'] = (self.data['resistance'] - self.data['close']) / self.data['close']
        
        # Time-based features
        self.data['hour'] = self.data['priceDateTime'].dt.hour
        self.data['minute'] = self.data['priceDateTime'].dt.minute
        self.data['day_of_week'] = self.data['priceDateTime'].dt.dayofweek
        
    def create_target(self):
        """สร้าง target สำหรับ binary option (ขึ้น/ลงใน 5 นาที)"""
        # คำนวณ price ในอนาคต 5 นาที
        future_price = self.data['close'].shift(-5)
        
        # สร้าง target: 1 = ขึ้น, 0 = ลง
        self.data['target'] = (future_price > self.data['close']).astype(int)
        
        # ลบแถวสุดท้ายที่ไม่มีข้อมูลอนาคต
        self.data = self.data[:-5]
        
    def prepare_features(self):
        """เตรียม features สำหรับ training"""
        feature_columns = [
            'price_change', 'high_low_ratio', 'open_close_ratio',
            'ma_5_ratio', 'ma_10_ratio', 'ma_20_ratio', 'ma_50_ratio',
            'rsi', 'bb_position', 'volatility_ratio',
            'momentum_5', 'momentum_10', 'support_distance', 'resistance_distance',
            'hour', 'minute', 'day_of_week'
        ]
        
        self.X = self.data[feature_columns]
        self.y = self.data['target']
        
        # แบ่งข้อมูล train/test
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            self.X, self.y, test_size=0.2, random_state=42, stratify=self.y
        )
        
        # Scale features
        self.X_train_scaled = self.scaler.fit_transform(self.X_train)
        self.X_test_scaled = self.scaler.transform(self.X_test)
        
        print(f"Features: {len(feature_columns)}")
        print(f"Training samples: {len(self.X_train)}")
        print(f"Test samples: {len(self.X_test)}")
        print(f"Target distribution: {self.y.value_counts().to_dict()}")
        
    def train_models(self):
        """เทรนโมเดลหลายแบบ"""
        models = {
            'RandomForest': RandomForestClassifier(n_estimators=100, random_state=42),
            'GradientBoosting': GradientBoostingClassifier(n_estimators=100, random_state=42),
            'LogisticRegression': LogisticRegression(random_state=42, max_iter=1000)
        }
        
        for name, model in models.items():
            print(f"\nกำลังเทรน {name}...")
            
            if name == 'LogisticRegression':
                model.fit(self.X_train_scaled, self.y_train)
                y_pred = model.predict(self.X_test_scaled)
                y_pred_proba = model.predict_proba(self.X_test_scaled)[:, 1]
            else:
                model.fit(self.X_train, self.y_train)
                y_pred = model.predict(self.X_test)
                y_pred_proba = model.predict_proba(self.X_test)[:, 1]
            
            # คำนวณ metrics
            accuracy = accuracy_score(self.y_test, y_pred)
            
            # คำนวณ win rate สำหรับ binary option
            # ใช้ threshold 0.5 สำหรับการทำนาย
            binary_predictions = (y_pred_proba > 0.5).astype(int)
            win_rate = accuracy_score(self.y_test, binary_predictions)
            
            # คำนวณ profit factor (simplified)
            correct_predictions = (binary_predictions == self.y_test)
            profit_factor = correct_predictions.sum() / len(correct_predictions) if len(correct_predictions) > 0 else 0
            
            self.models[name] = model
            self.results[name] = {
                'accuracy': accuracy,
                'win_rate': win_rate,
                'profit_factor': profit_factor,
                'predictions': y_pred,
                'probabilities': y_pred_proba
            }
            
            print(f"{name} - Accuracy: {accuracy:.4f}, Win Rate: {win_rate:.4f}")
            
    def evaluate_models(self):
        """ประเมินผลโมเดล"""
        print("\n" + "="*50)
        print("ผลการประเมินโมเดล")
        print("="*50)
        
        best_model = None
        best_score = 0
        
        for name, results in self.results.items():
            print(f"\n{name}:")
            print(f"  Accuracy: {results['accuracy']:.4f}")
            print(f"  Win Rate: {results['win_rate']:.4f}")
            print(f"  Profit Factor: {results['profit_factor']:.4f}")
            
            # หาโมเดลที่ดีที่สุด (ใช้ win rate เป็นหลัก)
            if results['win_rate'] > best_score:
                best_score = results['win_rate']
                best_model = name
        
        print(f"\nโมเดลที่ดีที่สุด: {best_model} (Win Rate: {best_score:.4f})")
        return best_model
        
    def save_models(self):
        """บันทึกโมเดลและ scaler"""
        print("\nกำลังบันทึกโมเดล...")
        
        # บันทึก scaler
        joblib.dump(self.scaler, 'scaler.pkl')
        
        # บันทึกโมเดลแต่ละตัว
        for name, model in self.models.items():
            joblib.dump(model, f'{name.lower()}_model.pkl')
            
        print("บันทึกโมเดลเสร็จสิ้น")
        
    def generate_mql5_code(self, best_model_name):
        """สร้าง MQL5 code สำหรับใช้โมเดล"""
        print(f"\nกำลังสร้าง MQL5 code สำหรับ {best_model_name}...")
        
        # โหลดโมเดลที่ดีที่สุด
        best_model = self.models[best_model_name]
        scaler = self.scaler
        
        # สร้าง feature names
        feature_names = [
            'price_change', 'high_low_ratio', 'open_close_ratio',
            'ma_5_ratio', 'ma_10_ratio', 'ma_20_ratio', 'ma_50_ratio',
            'rsi', 'bb_position', 'volatility_ratio',
            'momentum_5', 'momentum_10', 'support_distance', 'resistance_distance',
            'hour', 'minute', 'day_of_week'
        ]
        
        # สร้าง MQL5 code
        mql5_code = f"""
//+------------------------------------------------------------------+
//| {best_model_name} Binary Option Trading Model
//+------------------------------------------------------------------+
#property copyright "ML Model Generated"
#property version   "1.00"
#property strict

// Model parameters
double model_weights[{len(feature_names)}];
double model_intercept = 0;
double scaler_mean[{len(feature_names)}];
double scaler_scale[{len(feature_names)}];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{{
    // Initialize model parameters (extracted from Python model)
    initializeModelParameters();
    return(INIT_SUCCEEDED);
}}

//+------------------------------------------------------------------+
//| Initialize model parameters                                     |
//+------------------------------------------------------------------+
void initializeModelParameters()
{{
    // This function should be populated with actual model parameters
    // extracted from the trained model
    // For now, we'll use placeholder values
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        model_weights[i] = 0.0;
        scaler_mean[i] = 0.0;
        scaler_scale[i] = 1.0;
    }}
}}

//+------------------------------------------------------------------+
//| Calculate features                                              |
//+------------------------------------------------------------------+
void calculateFeatures(double &features[])
{{
    double close = iClose(Symbol(), Period(), 0);
    double open = iOpen(Symbol(), Period(), 0);
    double high = iHigh(Symbol(), Period(), 0);
    double low = iLow(Symbol(), Period(), 0);
    
    // Price changes
    features[0] = (close - iClose(Symbol(), Period(), 1)) / iClose(Symbol(), Period(), 1); // price_change
    features[1] = high / low; // high_low_ratio
    features[2] = open / close; // open_close_ratio
    
    // Moving averages
    double ma5 = iMA(Symbol(), Period(), 5, 0, MODE_SMA, PRICE_CLOSE, 0);
    double ma10 = iMA(Symbol(), Period(), 10, 0, MODE_SMA, PRICE_CLOSE, 0);
    double ma20 = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double ma50 = iMA(Symbol(), Period(), 50, 0, MODE_SMA, PRICE_CLOSE, 0);
    
    features[3] = close / ma5; // ma_5_ratio
    features[4] = close / ma10; // ma_10_ratio
    features[5] = close / ma20; // ma_20_ratio
    features[6] = close / ma50; // ma_50_ratio
    
    // RSI
    features[7] = iRSI(Symbol(), Period(), 14, PRICE_CLOSE, 0); // rsi
    
    // Bollinger Bands
    double bb_middle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double bb_std = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double bb_upper = bb_middle + (bb_std * 2);
    double bb_lower = bb_middle - (bb_std * 2);
    features[8] = (close - bb_lower) / (bb_upper - bb_lower); // bb_position
    
    // Volatility
    features[9] = bb_std / close; // volatility_ratio
    
    // Momentum
    features[10] = (close / iClose(Symbol(), Period(), 5)) - 1; // momentum_5
    features[11] = (close / iClose(Symbol(), Period(), 10)) - 1; // momentum_10
    
    // Support/Resistance
    double support = iLow(Symbol(), Period(), iLowest(Symbol(), Period(), MODE_LOW, 20, 0));
    double resistance = iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, 20, 0));
    features[12] = (close - support) / close; // support_distance
    features[13] = (resistance - close) / close; // resistance_distance
    
    // Time features
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    features[14] = dt.hour; // hour
    features[15] = dt.min; // minute
    features[16] = dt.day_of_week; // day_of_week
}}

//+------------------------------------------------------------------+
//| Predict using model                                            |
//+------------------------------------------------------------------+
double predict()
{{
    double features[{len(feature_names)}];
    calculateFeatures(features);
    
    // Scale features
    double scaled_features[{len(feature_names)}];
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        scaled_features[i] = (features[i] - scaler_mean[i]) / scaler_scale[i];
    }}
    
    // Make prediction (simplified linear model)
    double prediction = model_intercept;
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        prediction += model_weights[i] * scaled_features[i];
    }}
    
    return 1.0 / (1.0 + MathExp(-prediction)); // Sigmoid function
}}

//+------------------------------------------------------------------+
//| Expert tick function                                           |
//+------------------------------------------------------------------+
void OnTick()
{{
    double probability = predict();
    
    // Trading logic
    if(probability > 0.6) // Strong buy signal
    {{
        Print("BUY Signal - Probability: ", probability);
        // Add your buy logic here
    }}
    else if(probability < 0.4) // Strong sell signal
    {{
        Print("SELL Signal - Probability: ", probability);
        // Add your sell logic here
    }}
}}

//+------------------------------------------------------------------+
"""
        
        # บันทึก MQL5 code
        with open(f'{best_model_name.lower()}_model.mq5', 'w') as f:
            f.write(mql5_code)
            
        print(f"สร้างไฟล์ {best_model_name.lower()}_model.mq5 เสร็จสิ้น")
        
    def run_complete_analysis(self):
        """รันการวิเคราะห์ทั้งหมด"""
        print("เริ่มการวิเคราะห์โมเดล ML สำหรับ Binary Option Trading")
        print("="*60)
        
        # 1. โหลดและ preprocess ข้อมูล
        self.load_and_preprocess_data()
        
        # 2. เตรียม features
        self.prepare_features()
        
        # 3. เทรนโมเดล
        self.train_models()
        
        # 4. ประเมินผล
        best_model = self.evaluate_models()
        
        # 5. บันทึกโมเดล
        self.save_models()
        
        # 6. สร้าง MQL5 code
        self.generate_mql5_code(best_model)
        
        print("\nการวิเคราะห์เสร็จสิ้น!")
        return best_model

if __name__ == "__main__":
    # สร้าง instance และรันการวิเคราะห์
    ml_analyzer = BinaryOptionMLModels()
    best_model = ml_analyzer.run_complete_analysis() 