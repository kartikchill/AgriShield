import json
import contextlib
import os
from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from .localization.engine import translator

from . import models, schemas, weather_service, predictor, epidemiology_engine
from .database import engine, get_db, SessionLocal
from .seed_data import seed_etl_thresholds, seed_ipm_advisory_matrix, seed_diagnostic_labs, seed_hotspots
from .pest_routes import router as pest_router
from .referral_routes import router as referral_router
from .hotspot_routes import router as hotspot_router
from .learning_routes import router as learning_router
from .user_routes import router as user_router
from .integration_routes import router as integration_router

import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'Model B Vision')))
from vision_engine import vision_model
from routes import router as vision_router

models.Base.metadata.create_all(bind=engine)

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    # Load Model B Vision AI
    try:
        vision_model.load()
    except Exception as e:
        print(f"[WARNING] Model B could not be loaded: {e}")
    # Seed reference data on startup
    db = SessionLocal()
    try:
        seed_etl_thresholds(db)
        seed_ipm_advisory_matrix(db)
        seed_diagnostic_labs(db)
        seed_hotspots(db)
    finally:
        db.close()
    yield

app = FastAPI(title="Crop Risk System - Model A & ETL Rule Engine", lifespan=lifespan)

from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(pest_router)
app.include_router(referral_router)
app.include_router(hotspot_router)
app.include_router(vision_router)
app.include_router(learning_router)
app.include_router(user_router)
app.include_router(integration_router)

from pydantic import BaseModel
from typing import Optional
import os
import shutil

class ActiveLearningSubmit(BaseModel):
    ticket_id: str
    crop: str
    disease: str
    image_path: Optional[str] = None
    weather_vector: dict
    farmer_feedback: str

@app.post("/api/v1/active-learning/submit")
def submit_active_learning(payload: ActiveLearningSubmit, db: Session = Depends(get_db)):
    # 1. Dataset Ingestion
    if payload.image_path and os.path.exists(payload.image_path):
        folder_name = f"{payload.crop.replace(' ', '_')}__{payload.disease.replace(' ', '_')}"
        target_dir = os.path.join("D:\\PDD2\\Active Learning Loop\\dataset", folder_name)
        os.makedirs(target_dir, exist_ok=True)
        filename = os.path.basename(payload.image_path)
        shutil.copy2(payload.image_path, os.path.join(target_dir, filename))

    # 2. Weather Feature Vector Logging
    wv = payload.weather_vector
    new_feature = models.XGBoostFeatureStore(
        ticket_id=payload.ticket_id,
        crop=payload.crop,
        disease=payload.disease,
        temp_mean=wv.get("temp_mean", 0.0),
        rh_min=wv.get("rh_min", 0.0),
        rh_max=wv.get("rh_max", 0.0),
        rain_sum=wv.get("rain_sum", 0.0),
        p_days=wv.get("p_days", 0.0),
        outbreak_label=wv.get("outbreak_label", 0)
    )
    db.add(new_feature)
    db.commit()

    # 3. Return counts
    golden_count = db.query(models.RetrainingArchive).count()
    feature_count = db.query(models.XGBoostFeatureStore).count()

    return {
        "status": "success",
        "golden_dataset_count": golden_count,
        "feature_vector_count": feature_count
    }

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def read_root():
    return FileResponse("static/index.html")

@app.post("/api/assess-risk", response_model=schemas.AssessRiskResponse)
async def assess_risk(req: schemas.AssessRiskRequest, db: Session = Depends(get_db), accept_language: str = Header(default="en")):
    # 1. Save field
    db_field = models.Field(
        crop_type=req.crop_type,
        crop_variety=req.crop_variety,
        growth_stage=req.growth_stage,
        soil_type=req.soil_type,
        latitude=req.latitude,
        longitude=req.longitude
    )
    db.add(db_field)
    db.commit()
    db.refresh(db_field)

    # 2. Fetch Open-Meteo data
    try:
        daily_weather = await weather_service.fetch_weather_forecast(req.latitude, req.longitude)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch weather: {repr(e)}")
        
    if not daily_weather or len(daily_weather) < 4:
         raise HTTPException(status_code=500, detail="Incomplete weather data returned")

    # 3. Predict diseases for TODAY
    today_weather = daily_weather[0]
    diseases = epidemiology_engine.calculate_multi_disease_risk(req.crop_type, today_weather, req.growth_stage)

    # 4. Generate 4-day forecast for weather
    day_labels = ["Today", "Tomorrow", "+2 Days", "+3 Days"]
    forecasts = []
    
    for i, day_weather in enumerate(daily_weather):
        # We calculate max risk for that day just to populate the legacy ForecastDay fields
        day_diseases = epidemiology_engine.calculate_multi_disease_risk(req.crop_type, day_weather, req.growth_stage)
        max_risk = max([d.score for d in day_diseases]) if day_diseases else 0.0
        max_level = "HIGH" if max_risk >= 70 else ("MEDIUM" if max_risk >= 40 else "LOW")
        
        forecasts.append(schemas.ForecastDay(
            day=day_labels[i],
            risk=max_risk,
            level=max_level,
            temp=day_weather["avg_temp"],
            humidity=day_weather["avg_humidity"],
            rain=day_weather["total_rain"]
        ))
        
    # Check if there's any HIGH risk disease today
    has_high_risk = any(d.risk_level == "HIGH" for d in diseases)
    
    # Summaries and recommendations
    if has_high_risk:
        summary = "Environmental conditions are highly favorable for disease development."
        recommendation = "Field conditions indicate high risk for your crop. Tap the information icon on the disease cards for specific threshold breakdowns."
    else:
        summary = "Conditions are stable for disease development."
        recommendation = "Maintain regular scouting and monitoring routines."
        
    lang = accept_language.split(",")[0].split("-")[0].lower() # e.g. "en-US,en;q=0.9" -> "en"
    
    # Translate outputs if language provided
    def t_str(text: str) -> str:
        if not text: return text
        key = translator._map_to_key(text)
        if key: return translator.get_text(key, lang)
        return text

    summary = t_str(summary)
    recommendation = t_str(recommendation)
    
    translated_diseases = []
    for d in diseases:
        td = d.model_copy() if hasattr(d, "model_copy") else d.copy()
        td.disease_name = t_str(td.disease_name)
        td.risk_level = t_str(td.risk_level)
        eb = td.explanation_breakdown.model_copy() if hasattr(td.explanation_breakdown, "model_copy") else td.explanation_breakdown.copy()
        eb.field_metrics = t_str(eb.field_metrics)
        eb.required_thresholds = t_str(eb.required_thresholds)
        td.explanation_breakdown = eb
        translated_diseases.append(td)

    # Optional IPM mapping
    ipm = None
    if has_high_risk:
        ipm_record = db.query(models.IPMAdvisoryMatrix).filter(models.IPMAdvisoryMatrix.crop_name.ilike(req.crop_type)).first()
        if ipm_record:
            ipm = schemas.IPMAdvisoryResponse(
                cultural_advisory=t_str(ipm_record.cultural_advisory),
                biological_advisory=t_str(ipm_record.biological_advisory) if ipm_record.biological_advisory else None,
                chemical_name=ipm_record.chemical_name,
                dosage_per_liter=ipm_record.dosage_per_liter,
                required_ppe=t_str(ipm_record.required_ppe) if ipm_record.required_ppe else None,
                phi_days=ipm_record.phi_days,
                re_entry_interval_hours=ipm_record.re_entry_interval_hours
            )

    return schemas.AssessRiskResponse(
        field_id=db_field.id,
        diseases=translated_diseases,
        summary=summary,
        forecast=forecasts,
        recommendation=recommendation,
        ipm_advisory=ipm
    )

# Mount static files
app.mount('/static', StaticFiles(directory='static'), name='static')

@app.get('/')
def read_root():
    return FileResponse('static/index.html')

