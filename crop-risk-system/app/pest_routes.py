from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import List

from .database import get_db
from .models import ETLThreshold, SensorTrapLog
from .schemas import SensorLogCreate, SensorLogResponse, ETLThresholdResponse
from .etl_engine import evaluate_pest_risk
from .localization.engine import translator

router = APIRouter(prefix="/api/v1/pest-surveillance", tags=["Pest Surveillance"])

@router.post("/log", response_model=SensorLogResponse)
def log_sensor_data(payload: SensorLogCreate, db: Session = Depends(get_db), accept_language: str = Header(default="en")):
    try:
        log_entry = evaluate_pest_risk(db, payload)

        # log_entry is a SQLAlchemy ORM object — build dict manually
        log_dict = {
            "id": log_entry.id,
            "field_id": log_entry.field_id,
            "farmer_id": log_entry.farmer_id,
            "crop_name": log_entry.crop_name,
            "pest_name": log_entry.pest_name,
            "metric_type": log_entry.metric_type,
            "observed_value": log_entry.observed_value,
            "latitude": log_entry.latitude,
            "longitude": log_entry.longitude,
            "status": log_entry.status,
            "advisory": log_entry.advisory,
            "timestamp": log_entry.timestamp.isoformat() if log_entry.timestamp else None,
            "ipm_advisory": getattr(log_entry, "ipm_advisory", None),
        }

        lang = accept_language.split(",")[0].split("-")[0].lower()
        translated = translator.translate_payload(log_dict, lang)
        return translated

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history/{field_id}", response_model=List[SensorLogResponse])
def get_field_history(field_id: str, db: Session = Depends(get_db)):
    logs = db.query(SensorTrapLog).filter(SensorTrapLog.field_id == field_id)\
             .order_by(SensorTrapLog.timestamp.desc()).all()
    return logs

@router.get("/thresholds", response_model=List[ETLThresholdResponse])
def get_all_thresholds(db: Session = Depends(get_db)):
    thresholds = db.query(ETLThreshold).all()
    return thresholds
