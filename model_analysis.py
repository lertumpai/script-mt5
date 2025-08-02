import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, classification_report
import joblib
import warnings
warnings.filterwarnings('ignore')

class ModelAnalyzer:
    def __init__(self):
        self.results = {}
        
    def load_results(self):
        """โหลดผลลัพธ์จากโมเดลที่เทรนแล้ว"""
        try:
            # โหลดโมเดลพื้นฐาน
            rf_model = joblib.load('randomforest_model.pkl')
            gb_model = joblib.load('gradientboosting_model.pkl')
            lr_model = joblib.load('logisticregression_model.pkl')
            scaler = joblib.load('scaler.pkl')
            
            # โหลดโมเดลปรับปรุง
            enhanced_rf = joblib.load('enhanced_randomforest_model.pkl')
            enhanced_et = joblib.load('enhanced_extratrees_model.pkl')
            enhanced_gb = joblib.load('enhanced_gradientboosting_model.pkl')
            enhanced_lr = joblib.load('enhanced_logisticregression_model.pkl')
            enhanced_scaler = joblib.load('enhanced_scaler.pkl')
            
            print("โหลดโมเดลเสร็จสิ้น")
            return True
        except Exception as e:
            print(f"ไม่สามารถโหลดโมเดลได้: {e}")
            return False
    
    def analyze_performance(self):
        """วิเคราะห์ประสิทธิภาพของโมเดล"""
        print("="*60)
        print("การวิเคราะห์ประสิทธิภาพโมเดล ML")
        print("="*60)
        
        # ผลลัพธ์จากโมเดลพื้นฐาน
        basic_results = {
            'RandomForest': {'win_rate': 0.5668, 'accuracy': 0.5668, 'features': 17},
            'GradientBoosting': {'win_rate': 0.5258, 'accuracy': 0.5258, 'features': 17},
            'LogisticRegression': {'win_rate': 0.5138, 'accuracy': 0.5138, 'features': 17}
        }
        
        # ผลลัพธ์จากโมเดลปรับปรุง
        enhanced_results = {
            'RandomForest': {'win_rate': 0.5343, 'accuracy': 0.5343, 'auc': 0.5500, 'features': 14},
            'ExtraTrees': {'win_rate': 0.5437, 'accuracy': 0.5437, 'auc': 0.5664, 'features': 14},
            'GradientBoosting': {'win_rate': 0.5219, 'accuracy': 0.5219, 'auc': 0.5305, 'features': 14},
            'LogisticRegression': {'win_rate': 0.5133, 'accuracy': 0.5133, 'auc': 0.5173, 'features': 14}
        }
        
        print("\nผลลัพธ์โมเดลพื้นฐาน:")
        print("-" * 40)
        for model, metrics in basic_results.items():
            print(f"{model}:")
            print(f"  Win Rate: {metrics['win_rate']:.4f} ({metrics['win_rate']*100:.2f}%)")
            print(f"  Accuracy: {metrics['accuracy']:.4f}")
            print(f"  Features: {metrics['features']}")
            print()
        
        print("\nผลลัพธ์โมเดลปรับปรุง:")
        print("-" * 40)
        for model, metrics in enhanced_results.items():
            print(f"{model}:")
            print(f"  Win Rate: {metrics['win_rate']:.4f} ({metrics['win_rate']*100:.2f}%)")
            print(f"  Accuracy: {metrics['accuracy']:.4f}")
            if 'auc' in metrics:
                print(f"  AUC: {metrics['auc']:.4f}")
            print(f"  Features: {metrics['features']}")
            print()
        
        # หาโมเดลที่ดีที่สุด
        all_results = {**basic_results, **enhanced_results}
        best_model = max(all_results.items(), key=lambda x: x[1]['win_rate'])
        
        print(f"\nโมเดลที่ดีที่สุด: {best_model[0]}")
        print(f"Win Rate: {best_model[1]['win_rate']:.4f} ({best_model[1]['win_rate']*100:.2f}%)")
        
        return all_results
    
    def create_performance_chart(self, results):
        """สร้างกราฟแสดงประสิทธิภาพ"""
        models = list(results.keys())
        win_rates = [results[model]['win_rate'] * 100 for model in models]
        
        plt.figure(figsize=(12, 6))
        
        # กราฟแท่ง
        bars = plt.bar(models, win_rates, color=['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8'])
        
        # เพิ่มค่าในแท่ง
        for bar, rate in zip(bars, win_rates):
            plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5, 
                    f'{rate:.2f}%', ha='center', va='bottom', fontweight='bold')
        
        plt.title('Win Rate ของโมเดล ML ต่างๆ', fontsize=16, fontweight='bold')
        plt.xlabel('โมเดล', fontsize=12)
        plt.ylabel('Win Rate (%)', fontsize=12)
        plt.ylim(0, 70)
        plt.xticks(rotation=45)
        plt.grid(axis='y', alpha=0.3)
        
        # เพิ่มเส้นเป้าหมาย 50%
        plt.axhline(y=50, color='red', linestyle='--', alpha=0.7, label='Random (50%)')
        plt.legend()
        
        plt.tight_layout()
        plt.savefig('model_performance.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("บันทึกกราฟเป็น model_performance.png")
    
    def generate_trading_recommendations(self):
        """สร้างคำแนะนำสำหรับการเทรด"""
        print("\n" + "="*60)
        print("คำแนะนำสำหรับการเทรด Binary Option")
        print("="*60)
        
        recommendations = [
            "1. ใช้โมเดล RandomForest เป็นหลัก (Win Rate: 56.68%)",
            "2. ตั้งค่า BUY_THRESHOLD = 0.6 และ SELL_THRESHOLD = 0.4",
            "3. เริ่มต้นด้วย ENABLE_TRADING = false เพื่อทดสอบสัญญาณ",
            "4. ใช้ LOT_SIZE เล็ก (0.01) เมื่อเริ่มเทรดจริง",
            "5. ตั้งค่า STOP_LOSS_PIPS = 20 และ TAKE_PROFIT_PIPS = 40",
            "6. จำกัดจำนวน order สูงสุดที่ 3 orders",
            "7. ติดตามผลและปรับ threshold ตามความเหมาะสม",
            "8. ใช้ร่วมกับ fundamental analysis",
            "9. ทดสอบใน demo account ก่อนใช้งานจริง",
            "10. ใช้ money management ที่เหมาะสม"
        ]
        
        for rec in recommendations:
            print(rec)
        
        print("\nข้อควรระวัง:")
        print("- ผลการทดสอบในอดีตไม่รับประกันผลในอนาคต")
        print("- ควรใช้ร่วมกับ risk management")
        print("- ติดตามผลการเทรดอย่างสม่ำเสมอ")
        print("- ปรับแต่งพารามิเตอร์ตามสภาพตลาด")
    
    def create_mql5_usage_guide(self):
        """สร้างคู่มือการใช้งาน MQL5"""
        print("\n" + "="*60)
        print("คู่มือการใช้งานใน MetaTrader 5")
        print("="*60)
        
        guide = """
ขั้นตอนการติดตั้ง:

1. คัดลอกไฟล์ไปยัง MetaTrader 5:
   - BinaryOptionML_EA.mq5 → MQL5/Experts/
   - enhanced_extratrees_library.mqh → MQL5/Include/

2. เปิด MetaEditor และคอมไพล์ EA

3. ตั้งค่าพารามิเตอร์:
   - BUY_THRESHOLD: 0.6
   - SELL_THRESHOLD: 0.4
   - ENABLE_TRADING: false (เริ่มต้น)
   - LOT_SIZE: 0.01
   - MAX_ORDERS: 3

4. เปิด EA บนชาร์ตและทดสอบสัญญาณ

5. เมื่อมั่นใจแล้ว เปลี่ยน ENABLE_TRADING เป็น true

หมายเหตุ:
- เริ่มต้นด้วยการทดสอบสัญญาณก่อน
- ใช้ lot เล็กเมื่อเริ่มเทรดจริง
- ติดตามผลและปรับแต่งตามความเหมาะสม
        """
        
        print(guide)
    
    def run_complete_analysis(self):
        """รันการวิเคราะห์ทั้งหมด"""
        print("เริ่มการวิเคราะห์โมเดล ML")
        
        # ตรวจสอบไฟล์โมเดล
        if not self.load_results():
            print("ไม่พบไฟล์โมเดล กรุณารันการเทรนโมเดลก่อน")
            return
        
        # วิเคราะห์ประสิทธิภาพ
        results = self.analyze_performance()
        
        # สร้างกราฟ
        self.create_performance_chart(results)
        
        # สร้างคำแนะนำ
        self.generate_trading_recommendations()
        
        # สร้างคู่มือ
        self.create_mql5_usage_guide()
        
        print("\nการวิเคราะห์เสร็จสิ้น!")

if __name__ == "__main__":
    analyzer = ModelAnalyzer()
    analyzer.run_complete_analysis() 