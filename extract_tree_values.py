#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extract Tree Values from XGBoost Model
ดึงค่าจริงจาก XGBoost model เพื่อใช้ใน MQL5
"""

import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
import warnings
warnings.filterwarnings('ignore')

def extract_tree_structure(model, feature_names):
    """ดึงโครงสร้างต้นไม้จาก XGBoost model"""
    trees = model.get_booster().get_dump()
    
    print("=== XGBoost Tree Structure ===")
    print(f"จำนวนต้นไม้: {len(trees)}")
    print(f"จำนวน features: {len(feature_names)}")
    print()
    
    mql5_code = []
    
    for i, tree in enumerate(trees[:10]):  # แสดง 10 ต้นแรก
        print(f"ต้นไม้ที่ {i+1}:")
        print(tree)
        print("-" * 50)
        
        # แปลงเป็น MQL5 code
        mql5_func = convert_tree_to_mql5(tree, i+1, feature_names)
        mql5_code.append(mql5_func)
    
    return mql5_code

def convert_tree_to_mql5(tree_dump, tree_id, feature_names):
    """แปลงต้นไม้เป็น MQL5 function"""
    
    # แยกบรรทัดของต้นไม้
    lines = tree_dump.strip().split('\n')
    
    # สร้าง MQL5 function
    func_name = f"PredictTree{tree_id}"
    mql5_code = f"double {func_name}()\n{{\n"
    
    # แปลงแต่ละบรรทัด
    for line in lines:
        if line.startswith('\t'):
            # Leaf node
            leaf_value = float(line.split('leaf=')[1])
            mql5_code += f"    return {leaf_value};\n"
        else:
            # Split node
            parts = line.split('[')
            if len(parts) > 1:
                feature_part = parts[1].split(']')[0]
                feature_name = feature_part.split('<')[0]
                
                # หา feature index
                try:
                    feature_idx = feature_names.index(feature_name)
                    threshold = feature_part.split('<')[1]
                    
                    mql5_code += f"    if(g_features[{feature_idx}] <= {threshold})\n"
                    mql5_code += f"    {{\n"
                except:
                    continue
    
    mql5_code += "}\n"
    return mql5_code

def create_sample_model():
    """สร้างโมเดลตัวอย่างเพื่อแสดงค่าจริง"""
    
    # สร้างข้อมูลตัวอย่าง
    np.random.seed(42)
    n_samples = 1000
    
    # สร้าง features ตัวอย่าง
    data = {
        'price_change': np.random.normal(0, 0.001, n_samples),
        'high_low_ratio': np.random.uniform(1.0001, 1.001, n_samples),
        'close_open_ratio': np.random.uniform(0.9999, 1.0001, n_samples),
        'price_vs_ma5': np.random.normal(0, 0.0005, n_samples),
        'price_vs_ma10': np.random.normal(0, 0.0005, n_samples),
        'price_vs_ma20': np.random.normal(0, 0.0005, n_samples),
        'volatility_5': np.random.uniform(0.0001, 0.001, n_samples),
        'volatility_10': np.random.uniform(0.0001, 0.001, n_samples),
        'rsi_5': np.random.uniform(20, 80, n_samples),
        'rsi_10': np.random.uniform(20, 80, n_samples),
        'momentum_3': np.random.normal(0, 0.001, n_samples),
        'momentum_5': np.random.normal(0, 0.001, n_samples),
        'volume_proxy': np.random.uniform(0.0001, 0.002, n_samples),
        'hour': np.random.randint(0, 24, n_samples),
        'minute': np.random.randint(0, 60, n_samples),
        'day_of_week': np.random.randint(0, 7, n_samples),
        'body_size': np.random.uniform(0.0001, 0.001, n_samples),
        'upper_shadow': np.random.uniform(0.0001, 0.001, n_samples),
        'lower_shadow': np.random.uniform(0.0001, 0.001, n_samples),
        'trend_5': np.random.randint(0, 2, n_samples),
        'trend_10': np.random.randint(0, 2, n_samples)
    }
    
    df = pd.DataFrame(data)
    
    # สร้าง target (CALL = 1, PUT = 0)
    df['target'] = (
        (df['price_change'] > 0) & 
        (df['rsi_5'] > 50) & 
        (df['trend_5'] == 1)
    ).astype(int)
    
    # เตรียม features
    feature_names = [col for col in df.columns if col != 'target']
    X = df[feature_names]
    y = df['target']
    
    # เทรน XGBoost
    model = xgb.XGBClassifier(
        n_estimators=10,  # 10 ต้นไม้
        max_depth=3,
        learning_rate=0.1,
        random_state=42
    )
    
    model.fit(X, y)
    
    return model, feature_names

def main():
    """ฟังก์ชันหลัก"""
    print("=== XGBoost Tree Value Extractor ===")
    
    try:
        # สร้างโมเดลตัวอย่าง
        model, feature_names = create_sample_model()
        
        # ดึงโครงสร้างต้นไม้
        mql5_functions = extract_tree_structure(model, feature_names)
        
        # สร้างไฟล์ MQL5
        with open('extracted_trees.mq5', 'w', encoding='utf-8') as f:
            f.write("//+------------------------------------------------------------------+\n")
            f.write("//| Extracted XGBoost Trees for MQL5\n")
            f.write("//+------------------------------------------------------------------+\n\n")
            
            for func in mql5_functions:
                f.write(func)
                f.write("\n")
        
        print("\n=== ไฟล์ที่สร้าง ===")
        print("extracted_trees.mq5 - ต้นไม้ที่ดึงจาก XGBoost")
        
        # แสดงตัวอย่างค่าจริง
        print("\n=== ตัวอย่างค่าจริงจากต้นไม้ที่ 1 ===")
        trees = model.get_booster().get_dump()
        if trees:
            print(trees[0])
        
    except Exception as e:
        print(f"เกิดข้อผิดพลาด: {e}")
        print("\n=== วิธีแก้ไข ===")
        print("1. ติดตั้ง Python dependencies:")
        print("   pip install pandas numpy xgboost scikit-learn")
        print("2. รัน script อีกครั้ง")

if __name__ == "__main__":
    main() 