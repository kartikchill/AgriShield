import numpy as np
import xgboost as xgb
import os
import joblib

# Load Model A and Feature Schema globally
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_PATH = os.path.join(_BASE_DIR, "Model A (dataset)", "model_a_risk_predictor.json")
FEATURES_PATH = os.path.join(_BASE_DIR, "Model A (dataset)", "model_a_features.pkl")

# Initialize and load model
model = xgb.XGBClassifier()
model.load_model(MODEL_PATH)

# (Optional) load the features list to verify or use if needed
# feature_schema = joblib.load(FEATURES_PATH)

def calculate_risk(weather_data: dict, growth_stage: str):
    """
    Calculates risk score using the trained XGBoost model.
    """
    # Create the feature array in the EXACT specified order:
    # 1. avg_temp
    # 2. min_temp
    # 3. max_temp
    # 4. avg_humidity
    # 5. hours_rh_above_90
    # 6. total_rain
    # 7. rolling_3d_rain
    # 8. rolling_3d_humidity
    
    features = np.array([[
        weather_data["avg_temp"],
        weather_data["min_temp"],
        weather_data["max_temp"],
        weather_data["avg_humidity"],
        weather_data["hours_rh_above_90"],
        weather_data["total_rain"],
        weather_data["rolling_3d_rain"],
        weather_data["rolling_3d_humidity"]
    ]])
    
    # Predict Probability
    # predict_proba returns [[prob_class_0, prob_class_1]]
    prob = model.predict_proba(features)[0][1]
    
    # Format the response
    risk_percentage = round(float(prob) * 100, 1)
    
    if risk_percentage >= 70.0:
        risk_level = "HIGH"
    elif risk_percentage >= 40.0:
        risk_level = "MEDIUM"
    else:
        risk_level = "LOW"
        
    # Generate human-readable factors based on the input data
    factors = []
    if weather_data["hours_rh_above_90"] >= 10:
        factors.append(f"High relative humidity (>90%) sustained for {weather_data['hours_rh_above_90']} hours")
    elif weather_data["avg_humidity"] >= 80:
        factors.append(f"Overall high average humidity ({weather_data['avg_humidity']}%)")
        
    if 15 <= weather_data["avg_temp"] <= 22:
        factors.append(f"Optimal average temperature for pathogen germination ({weather_data['avg_temp']}°C)")
        
    if weather_data["rolling_3d_rain"] > 10.0:
        factors.append(f"Significant cumulative rainfall promoting leaf wetness ({weather_data['rolling_3d_rain']}mm)")

    if not factors:
        factors.append("Environmental conditions are currently stable.")

    return {
        "risk": risk_percentage,
        "level": risk_level,
        "factors": factors
    }
