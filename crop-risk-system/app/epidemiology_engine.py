from typing import List, Dict, Any
from .schemas import DiseaseRisk, ExplanationBreakdown
from . import predictor

def _format_risk(score: float) -> str:
    if score >= 70.0:
        return "HIGH"
    elif score >= 40.0:
        return "MEDIUM"
    return "LOW"

def evaluate_apple_scab(weather_data: Dict[str, Any]) -> DiseaseRisk:
    # Mills' Period logic (Simplified for daily aggregation)
    # Apple Scab requires leaf wetness (high RH) and temp between 10-20C.
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 10.0
    if 10 <= temp <= 20 and rh >= 85:
        score = 85.0
    elif (5 <= temp < 10 or 20 < temp <= 25) and rh >= 80:
        score = 50.0
        
    return DiseaseRisk(
        disease_name="Apple Scab",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 10-20Â°C, Extended Leaf Wetness (RH > 85%)",
            citation="Source: Mills & Laplante (1951) - Mills' Periods for Apple Scab Infection"
        )
    )

def evaluate_late_blight(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    rain = weather_data["total_rain"]
    
    score = 15.0
    if 15 <= temp <= 20 and rh >= 90 and rain > 1:
        score = 92.0
    elif 10 <= temp <= 24 and rh >= 80:
        score = 65.0
        
    return DiseaseRisk(
        disease_name="Late Blight",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%, Rain: {rain}mm",
            required_thresholds="Temp: 15-20Â°C, RH > 90%, Frequent Rain",
            citation="Source: Wallin (1962) - Blitecast Model"
        )
    )

def evaluate_early_blight(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    rain = weather_data["total_rain"]
    
    score = 10.0
    if 21 <= temp <= 29 and rh >= 80 and rain < 5:
        score = 88.0
    elif 20 <= temp <= 32 and rh >= 75:
        score = 55.0
        
    return DiseaseRisk(
        disease_name="Early Blight",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%, Rain: {rain}mm",
            required_thresholds="Temp: 21-29Â°C, High morning RH, Low overall rain",
            citation="Source: Madden et al. (1978) - FAST System (TOMCAST)"
        )
    )

def evaluate_rice_blast(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 15.0
    if 25 <= temp <= 28 and rh >= 93:
        score = 95.0
    elif 22 <= temp <= 30 and rh >= 85:
        score = 60.0
        
    return DiseaseRisk(
        disease_name="Rice Blast",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 25-28Â°C, RH > 93%",
            citation="Source: IRRI (International Rice Research Institute) - Blast Epidemiology"
        )
    )

def evaluate_wheat_rust(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 10.0
    # Yellow rust (10-20C), Brown rust (15-25C), Stem rust (20-30C)
    if 10 <= temp <= 25 and rh >= 85:
        score = 85.0
    elif 5 <= temp <= 30 and rh >= 75:
        score = 45.0
        
    return DiseaseRisk(
        disease_name="Wheat Rust (Complex)",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 10-25Â°C, RH > 85%",
            citation="Source: FAO / Borlaug Global Rust Initiative"
        )
    )

def evaluate_cotton_bacterial_blight(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 10.0
    if 30 <= temp <= 34 and rh >= 85:
        score = 90.0
    elif 25 <= temp <= 36 and rh >= 75:
        score = 55.0
        
    return DiseaseRisk(
        disease_name="Bacterial Blight",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 30-34Â°C, RH > 85%",
            citation="Source: CICR (Central Institute for Cotton Research)"
        )
    )

def evaluate_sugarcane_red_rot(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 5.0
    if 29 <= temp <= 31 and rh >= 90:
        score = 85.0
    elif 25 <= temp <= 35 and rh >= 80:
        score = 50.0
        
    return DiseaseRisk(
        disease_name="Red Rot",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 29-31Â°C, RH > 90%",
            citation="Source: SBI (Sugarcane Breeding Institute)"
        )
    )

def evaluate_soybean_rust(weather_data: Dict[str, Any]) -> DiseaseRisk:
    temp = weather_data["avg_temp"]
    rh = weather_data["avg_humidity"]
    
    score = 5.0
    if 15 <= temp <= 28 and rh >= 75:
        score = 88.0
    
    return DiseaseRisk(
        disease_name="Soybean Rust",
        risk_level=_format_risk(score),
        score=score,
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Avg Temp: {temp}Â°C, Humidity: {rh}%",
            required_thresholds="Temp: 15-28Â°C, Extended Leaf Wetness (RH > 75%)",
            citation="Source: USDA - Asian Soybean Rust Modeling"
        )
    )

# Fallback XGBoost execution
def evaluate_fallback(weather_data: Dict[str, Any], growth_stage: str) -> DiseaseRisk:
    prediction = predictor.calculate_risk(weather_data, growth_stage)
    return DiseaseRisk(
        disease_name="General Disease Risk",
        risk_level=prediction["level"],
        score=prediction["risk"],
        explanation_breakdown=ExplanationBreakdown(
            field_metrics=f"Factors: {', '.join(prediction['factors'])}",
            required_thresholds="AI Ensemble Thresholds",
            citation="Source: AGRI-SHIELD Model A (XGBoost Ensemble)"
        )
    )

def calculate_multi_disease_risk(crop: str, weather_data: Dict[str, Any], growth_stage: str) -> List[DiseaseRisk]:
    """
    Routes the weather data to the appropriate disease models based on the crop.
    """
    crop_lower = crop.lower()
    diseases = []
    
    if "apple" in crop_lower:
        diseases.append(evaluate_apple_scab(weather_data))
    elif "tomato" in crop_lower or "potato" in crop_lower:
        diseases.append(evaluate_late_blight(weather_data))
        diseases.append(evaluate_early_blight(weather_data))
    elif "rice" in crop_lower:
        diseases.append(evaluate_rice_blast(weather_data))
    elif "wheat" in crop_lower:
        diseases.append(evaluate_wheat_rust(weather_data))
    elif "cotton" in crop_lower:
        diseases.append(evaluate_cotton_bacterial_blight(weather_data))
    elif "sugar" in crop_lower:
        diseases.append(evaluate_sugarcane_red_rot(weather_data))
    elif "soybean" in crop_lower:
        diseases.append(evaluate_soybean_rust(weather_data))
    else:
        # Fallback for unmapped crops
        diseases.append(evaluate_fallback(weather_data, growth_stage))
        
    return diseases
