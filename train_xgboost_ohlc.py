#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XGBoost Binary Option M1 Model Trainer - OHLC Data
เทรนโมเดล XGBoost จากไฟล์ ohlc.csv
"""

import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import warnings
warnings.filterwarnings('ignore')

class OHLCXGBoostTrainer:
    def __init__(self, csv_file_path):
        self.csv_file_path = csv_file_path
        self.model = None
        self.feature_names = []
        
    def load_and_preprocess_data(self):
        """โหลดและประมวลผลข้อมูลจาก OHLC CSV"""
        print("กำลังโหลดข้อมูลจาก OHLC CSV...")
        
        # อ่านไฟล์ CSV
        df = pd.read_csv(self.csv_file_path)
        
        # แปลงคอลัมน์เวลา
        df['priceDateTime'] = pd.to_datetime(df['priceDateTime'])
        df = df.sort_values('priceDateTime')
        
        print(f"ข้อมูลทั้งหมด: {len(df)} แถว")
        print(f"ช่วงเวลา: {df['priceDateTime'].min()} ถึง {df['priceDateTime'].max()}")
        
        # สร้าง features สำหรับ technical analysis
        df = self.create_technical_features(df)
        
        # สร้าง target (CALL = 1, PUT = 0)
        df = self.create_target(df)
        
        # ลบแถวที่มี NaN
        df = df.dropna()
        
        print(f"ข้อมูลหลังประมวลผล: {len(df)} แถว")
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
    
    def extract_tree_values(self):
        """ดึงค่าจริงจากต้นไม้"""
        if self.model is None:
            print("ไม่มีโมเดลที่เทรนแล้ว")
            return None
        
        trees = self.model.get_booster().get_dump()
        print(f"\nดึงต้นไม้ {len(trees)} ต้น")
        
        tree_values = []
        for i, tree in enumerate(trees[:10]):  # 10 ต้นแรก
            tree_data = self.parse_tree(tree, i+1)
            tree_values.append(tree_data)
            print(f"ต้นไม้ที่ {i+1}: {tree_data}")
        
        return tree_values
    
    def parse_tree(self, tree_dump, tree_id):
        """แปลงต้นไม้เป็นข้อมูล"""
        lines = tree_dump.strip().split('\n')
        tree_data = {
            'tree_id': tree_id,
            'splits': [],
            'leaves': []
        }
        
        for line in lines:
            if line.startswith('\t'):
                # Leaf node
                leaf_value = float(line.split('leaf=')[1])
                tree_data['leaves'].append(leaf_value)
            else:
                # Split node
                parts = line.split('[')
                if len(parts) > 1:
                    feature_part = parts[1].split(']')[0]
                    feature_name = feature_part.split('<')[0]
                    threshold = feature_part.split('<')[1]
                    
                    tree_data['splits'].append({
                        'feature': feature_name,
                        'threshold': float(threshold)
                    })
        
        return tree_data
    
    def generate_mql5_trees(self, tree_values):
        """สร้าง MQL5 tree functions"""
        mql5_code = []
        
        for tree_data in tree_values:
            tree_id = tree_data['tree_id']
            splits = tree_data['splits']
            leaves = tree_data['leaves']
            
            func_code = self.create_tree_function(tree_id, splits, leaves)
            mql5_code.append(func_code)
        
        return mql5_code
    
    def create_tree_function(self, tree_id, splits, leaves):
        """สร้าง MQL5 tree function"""
        func_name = f"PredictTree{tree_id}"
        
        # หา feature index
        feature_map = {
            'price_change': 0, 'high_low_ratio': 1, 'close_open_ratio': 2,
            'price_vs_ma5': 3, 'price_vs_ma10': 4, 'price_vs_ma20': 5,
            'volatility_5': 6, 'volatility_10': 7, 'rsi_5': 8, 'rsi_10': 9,
            'momentum_3': 10, 'momentum_5': 11, 'volume_proxy': 12,
            'hour': 13, 'minute': 14, 'day_of_week': 15,
            'body_size': 16, 'upper_shadow': 17, 'lower_shadow': 18,
            'trend_5': 19, 'trend_10': 20
        }
        
        mql5_code = f"double {func_name}()\n{{\n"
        
        # สร้าง tree logic
        leaf_index = 0
        for i, split in enumerate(splits):
            feature_idx = feature_map.get(split['feature'], 0)
            threshold = split['threshold']
            
            mql5_code += f"    if(g_features[{feature_idx}] <= {threshold})\n"
            mql5_code += f"    {{\n"
            
            # ถ้าเป็น split สุดท้าย ให้ใส่ leaf values
            if i == len(splits) - 1:
                mql5_code += f"        return {leaves[leaf_index]};\n"
                leaf_index += 1
                mql5_code += f"    }}\n"
                mql5_code += f"    else\n"
                mql5_code += f"    {{\n"
                mql5_code += f"        return {leaves[leaf_index]};\n"
                mql5_code += f"    }}\n"
            else:
                mql5_code += f"        // Continue to next split\n"
        
        mql5_code += f"}}\n"
        return mql5_code
    
    def save_model(self, filename='xgboost_ohlc_model.pkl'):
        """บันทึกโมเดล"""
        if self.model is not None:
            joblib.dump(self.model, filename)
            print(f"บันทึกโมเดลแล้ว: {filename}")
    
    def generate_updated_library(self, tree_values):
        """สร้าง Library ที่อัพเดทแล้ว"""
        # อ่าน Library เดิม
        with open('XGBoostSignalLibrary.mqh', 'r', encoding='utf-8') as f:
            library_content = f.read()
        
        # สร้าง tree functions ใหม่
        tree_functions = []
        for tree_data in tree_values:
            tree_id = tree_data['tree_id']
            splits = tree_data['splits']
            leaves = tree_data['leaves']
            
            func_code = self.create_tree_function(tree_id, splits, leaves)
            tree_functions.append(func_code)
        
        # แทนที่ tree functions ใน Library
        # หาตำแหน่งของ tree functions เดิม
        start_marker = "//+------------------------------------------------------------------+\n//| Tree Prediction Functions (10 ต้นแรก)                         |\n//+------------------------------------------------------------------+"
        end_marker = "//+------------------------------------------------------------------+\n//| Generic Tree Prediction (สำหรับต้นไม้ที่เหลือ 11-50)          |\n//+------------------------------------------------------------------+"
        
        # สร้าง tree functions ใหม่
        new_tree_functions = "\n".join(tree_functions)
        
        # แทนที่ใน Library
        updated_library = library_content.replace(
            "//+------------------------------------------------------------------+\n//| Tree Prediction Functions (10 ต้นแรก)                         |\n//+------------------------------------------------------------------+\n" +
            "double PredictTree1()\n{\n    if(g_features[0] <= -0.0001)\n    {\n        if(g_features[8] <= 45.5)\n            return 0.1;\n        else\n            return -0.2;\n    }\n    else\n    {\n        if(g_features[2] <= 1.0005)\n            return -0.1;\n        else\n            return 0.2;\n    }\n}\n\n" +
            "double PredictTree2()\n{\n    if(g_features[3] <= -0.0002)\n    {\n        if(g_features[9] <= 30.0)\n            return -0.3;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[6] <= 0.0005)\n            return 0.2;\n        else\n            return -0.1;\n    }\n}\n\n" +
            "double PredictTree3()\n{\n    if(g_features[10] <= 0.0001)\n    {\n        if(g_features[13] <= 12)\n            return -0.1;\n        else\n            return 0.2;\n    }\n    else\n    {\n        if(g_features[19] == 1)\n            return 0.3;\n        else\n            return -0.2;\n    }\n}\n\n" +
            "double PredictTree4()\n{\n    if(g_features[1] <= 1.0002)\n    {\n        if(g_features[16] <= 0.0005)\n            return -0.1;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[4] <= 0.0001)\n            return 0.2;\n        else\n            return -0.1;\n    }\n}\n\n" +
            "double PredictTree5()\n{\n    if(g_features[7] <= 0.0008)\n    {\n        if(g_features[15] <= 3)\n            return 0.1;\n        else\n            return -0.1;\n    }\n    else\n    {\n        if(g_features[20] == 1)\n            return 0.2;\n        else\n            return -0.2;\n    }\n}\n\n" +
            "double PredictTree6()\n{\n    if(g_features[8] <= 50.0)\n    {\n        if(g_features[0] <= 0.0)\n            return -0.2;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[19] == 1)\n            return 0.3;\n        else\n            return 0.1;\n    }\n}\n\n" +
            "double PredictTree7()\n{\n    if(g_features[12] <= 0.001)\n    {\n        if(g_features[14] <= 30)\n            return -0.1;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[17] <= 0.0005)\n            return 0.2;\n        else\n            return -0.1;\n    }\n}\n\n" +
            "double PredictTree8()\n{\n    if(g_features[9] <= 40.0)\n    {\n        if(g_features[11] <= 0.0002)\n            return -0.2;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[20] == 1)\n            return 0.2;\n        else\n            return -0.1;\n    }\n}\n\n" +
            "double PredictTree9()\n{\n    if(g_features[4] <= -0.0001)\n    {\n        if(g_features[16] <= 0.0003)\n            return -0.1;\n        else\n            return 0.1;\n    }\n    else\n    {\n        if(g_features[13] <= 8)\n            return 0.2;\n        else\n            return -0.1;\n    }\n}\n\n" +
            "double PredictTree10()\n{\n    if(g_features[6] <= 0.0006)\n    {\n        if(g_features[18] <= 0.0004)\n            return 0.1;\n        else\n            return -0.1;\n    }\n    else\n    {\n        if(g_features[15] <= 4)\n            return 0.2;\n        else\n            return -0.2;\n    }\n}\n\n",
            "//+------------------------------------------------------------------+\n//| Tree Prediction Functions (10 ต้นแรก) - Updated from OHLC Data |\n//+------------------------------------------------------------------+\n" + new_tree_functions + "\n"
        )
        
        # บันทึก Library ที่อัพเดทแล้ว
        with open('XGBoostSignalLibrary_Updated.mqh', 'w', encoding='utf-8') as f:
            f.write(updated_library)
        
        print("สร้าง Library ที่อัพเดทแล้ว: XGBoostSignalLibrary_Updated.mqh")

def main():
    """ฟังก์ชันหลัก"""
    print("=== XGBoost Binary Option M1 Model Trainer (OHLC Data) ===")
    
    # สร้าง trainer
    trainer = OHLCXGBoostTrainer('ohlc.csv')
    
    # โหลดและประมวลผลข้อมูล
    df = trainer.load_and_preprocess_data()
    
    # เตรียม features
    X, y = trainer.prepare_features(df)
    
    # เทรนโมเดล
    accuracy = trainer.train_model(X, y)
    
    # ดึงค่าจริงจากต้นไม้
    tree_values = trainer.extract_tree_values()
    
    # บันทึกโมเดล
    trainer.save_model()
    
    # สร้าง Library ที่อัพเดทแล้ว
    trainer.generate_updated_library(tree_values)
    
    print("\n=== เสร็จสิ้น ===")
    print(f"Win Rate: {accuracy*100:.2f}%")
    print("ไฟล์ที่สร้าง:")
    print("- xgboost_ohlc_model.pkl (โมเดล)")
    print("- XGBoostSignalLibrary_Updated.mqh (Library อัพเดท)")

if __name__ == "__main__":
    main() 