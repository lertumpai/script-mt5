import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, ExtraTreesClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, roc_auc_score
from sklearn.preprocessing import RobustScaler
import joblib
import warnings
warnings.filterwarnings('ignore')

class EnhancedBinaryOptionMLModels:
    def __init__(self, csv_file='ohlc.csv'):
        self.csv_file = csv_file
        self.data = None
        self.X = None
        self.y = None
        self.scaler = RobustScaler()
        self.models = {}
        self.results = {}
        
    def load_and_preprocess_data(self):
        """โหลดและ preprocess ข้อมูล OHLC"""
        print("กำลังโหลดข้อมูล...")
        self.data = pd.read_csv(self.csv_file)
        self.data['priceDateTime'] = pd.to_datetime(self.data['priceDateTime'])
        self.data = self.data.sort_values('priceDateTime').reset_index(drop=True)
        
        print(f"ข้อมูลทั้งหมด: {len(self.data)} แถว")
        
        # สร้าง features
        self.create_enhanced_features()
        
        # สร้าง target
        future_price = self.data['close'].shift(-5)
        self.data['target'] = (future_price > self.data['close']).astype(int)
        self.data = self.data[:-5].dropna()
        
        print(f"ข้อมูลหลังลบ NaN: {len(self.data)} แถว")
        
    def create_enhanced_features(self):
        """สร้าง enhanced features"""
        # Price features
        self.data['price_change'] = self.data['close'].pct_change()
        self.data['high_low_ratio'] = self.data['high'] / self.data['low']
        self.data['body_size'] = abs(self.data['close'] - self.data['open']) / self.data['close']
        
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
        
        # Momentum
        self.data['momentum_5'] = self.data['close'] / self.data['close'].shift(5) - 1
        self.data['momentum_10'] = self.data['close'] / self.data['close'].shift(10) - 1
        
        # Volatility
        self.data['volatility'] = self.data['close'].rolling(20).std() / self.data['close']
        
        # Time features
        self.data['hour'] = self.data['priceDateTime'].dt.hour
        self.data['day_of_week'] = self.data['priceDateTime'].dt.dayofweek
        
    def prepare_features(self):
        """เตรียม features"""
        feature_columns = [
            'price_change', 'high_low_ratio', 'body_size',
            'ma_5_ratio', 'ma_10_ratio', 'ma_20_ratio', 'ma_50_ratio',
            'rsi', 'bb_position', 'momentum_5', 'momentum_10', 'volatility',
            'hour', 'day_of_week'
        ]
        
        self.X = self.data[feature_columns]
        self.y = self.data['target']
        
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            self.X, self.y, test_size=0.2, random_state=42, stratify=self.y
        )
        
        self.X_train_scaled = self.scaler.fit_transform(self.X_train)
        self.X_test_scaled = self.scaler.transform(self.X_test)
        
        print(f"Features: {len(feature_columns)}")
        print(f"Training samples: {len(self.X_train)}")
        print(f"Test samples: {len(self.X_test)}")
        
    def train_models(self):
        """เทรนโมเดล"""
        models = {
            'RandomForest': RandomForestClassifier(n_estimators=200, max_depth=20, random_state=42),
            'ExtraTrees': ExtraTreesClassifier(n_estimators=200, max_depth=20, random_state=42),
            'GradientBoosting': GradientBoostingClassifier(n_estimators=200, learning_rate=0.1, random_state=42),
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
            
            accuracy = accuracy_score(self.y_test, y_pred)
            auc_score = roc_auc_score(self.y_test, y_pred_proba)
            win_rate = accuracy_score(self.y_test, (y_pred_proba > 0.5).astype(int))
            
            self.models[name] = model
            self.results[name] = {
                'accuracy': accuracy,
                'auc': auc_score,
                'win_rate': win_rate,
                'probabilities': y_pred_proba
            }
            
            print(f"{name} - Accuracy: {accuracy:.4f}, AUC: {auc_score:.4f}, Win Rate: {win_rate:.4f}")
            
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
            print(f"  AUC: {results['auc']:.4f}")
            print(f"  Win Rate: {results['win_rate']:.4f}")
            
            if results['win_rate'] > best_score:
                best_score = results['win_rate']
                best_model = name
        
        print(f"\nโมเดลที่ดีที่สุด: {best_model} (Win Rate: {best_score:.4f})")
        return best_model
        
    def save_models(self):
        """บันทึกโมเดล"""
        print("\nกำลังบันทึกโมเดล...")
        joblib.dump(self.scaler, 'enhanced_scaler.pkl')
        
        for name, model in self.models.items():
            joblib.dump(model, f'enhanced_{name.lower()}_model.pkl')
            
        print("บันทึกโมเดลเสร็จสิ้น")
        
    def generate_mql5_library(self, best_model_name):
        """สร้าง MQL5 library"""
        print(f"\nกำลังสร้าง MQL5 library สำหรับ {best_model_name}...")
        
        feature_names = [
            'price_change', 'high_low_ratio', 'body_size',
            'ma_5_ratio', 'ma_10_ratio', 'ma_20_ratio', 'ma_50_ratio',
            'rsi', 'bb_position', 'momentum_5', 'momentum_10', 'volatility',
            'hour', 'day_of_week'
        ]
        
        # สร้าง MQL5 library
        mql5_library = f"""
//+------------------------------------------------------------------+
//| Enhanced {best_model_name} Binary Option Library
//+------------------------------------------------------------------+
#property copyright "Enhanced ML Model Library"
#property version   "2.00"
#property library
#property strict

// Model parameters
double model_weights[{len(feature_names)}];
double model_intercept = 0;
double scaler_center[{len(feature_names)}];
double scaler_scale[{len(feature_names)}];

//+------------------------------------------------------------------+
//| Initialize model parameters                                     |
//+------------------------------------------------------------------+
void initializeModelParameters()
{{
    // Initialize with actual values from trained model
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        scaler_center[i] = 0.0;
        scaler_scale[i] = 1.0;
        model_weights[i] = 0.0;
    }}
    model_intercept = 0.0;
}}

//+------------------------------------------------------------------+
//| Calculate features                                             |
//+------------------------------------------------------------------+
void calculateFeatures(double &features[])
{{
    double close = iClose(Symbol(), Period(), 0);
    double open = iOpen(Symbol(), Period(), 0);
    double high = iHigh(Symbol(), Period(), 0);
    double low = iLow(Symbol(), Period(), 0);
    double prev_close = iClose(Symbol(), Period(), 1);
    
    // Price features
    features[0] = (close - prev_close) / prev_close;
    features[1] = high / low;
    features[2] = MathAbs(close - open) / close;
    
    // Moving averages
    features[3] = close / iMA(Symbol(), Period(), 5, 0, MODE_SMA, PRICE_CLOSE, 0);
    features[4] = close / iMA(Symbol(), Period(), 10, 0, MODE_SMA, PRICE_CLOSE, 0);
    features[5] = close / iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    features[6] = close / iMA(Symbol(), Period(), 50, 0, MODE_SMA, PRICE_CLOSE, 0);
    
    // RSI
    features[7] = iRSI(Symbol(), Period(), 14, PRICE_CLOSE, 0);
    
    // Bollinger Bands
    double bb_middle = iMA(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double bb_std = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double bb_upper = bb_middle + (bb_std * 2);
    double bb_lower = bb_middle - (bb_std * 2);
    features[8] = (close - bb_lower) / (bb_upper - bb_lower);
    
    // Momentum
    features[9] = (close / iClose(Symbol(), Period(), 5)) - 1;
    features[10] = (close / iClose(Symbol(), Period(), 10)) - 1;
    
    // Volatility
    features[11] = iStdDev(Symbol(), Period(), 20, 0, MODE_SMA, PRICE_CLOSE, 0) / close;
    
    // Time features
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    features[12] = dt.hour;
    features[13] = dt.day_of_week;
}}

//+------------------------------------------------------------------+
//| Predict probability                                            |
//+------------------------------------------------------------------+
double predictProbability()
{{
    double features[{len(feature_names)}];
    calculateFeatures(features);
    
    // Scale features
    double scaled_features[{len(feature_names)}];
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        scaled_features[i] = (features[i] - scaler_center[i]) / scaler_scale[i];
    }}
    
    // Make prediction
    double prediction = model_intercept;
    for(int i = 0; i < {len(feature_names)}; i++)
    {{
        prediction += model_weights[i] * scaled_features[i];
    }}
    
    return 1.0 / (1.0 + MathExp(-prediction));
}}

//+------------------------------------------------------------------+
//| Get trading signal                                             |
//+------------------------------------------------------------------+
string getTradingSignal(double buy_threshold = 0.6, double sell_threshold = 0.4)
{{
    double probability = predictProbability();
    
    if(probability > buy_threshold)
        return "BUY";
    else if(probability < sell_threshold)
        return "SELL";
    else
        return "HOLD";
}}

//+------------------------------------------------------------------+
"""
        
        # บันทึก MQL5 library
        with open(f'enhanced_{best_model_name.lower()}_library.mqh', 'w') as f:
            f.write(mql5_library)
            
        print(f"สร้างไฟล์ enhanced_{best_model_name.lower()}_library.mqh เสร็จสิ้น")
        
    def run_complete_analysis(self):
        """รันการวิเคราะห์ทั้งหมด"""
        print("เริ่มการวิเคราะห์ Enhanced ML Models")
        print("="*50)
        
        self.load_and_preprocess_data()
        self.prepare_features()
        self.train_models()
        best_model = self.evaluate_models()
        self.save_models()
        self.generate_mql5_library(best_model)
        
        print("\nการวิเคราะห์เสร็จสิ้น!")
        return best_model

if __name__ == "__main__":
    ml_analyzer = EnhancedBinaryOptionMLModels()
    best_model = ml_analyzer.run_complete_analysis() 