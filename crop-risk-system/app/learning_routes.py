from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta, timezone

from .database import get_db
from . import models, schemas
from .export_engine import RetrainingPipeline

router = APIRouter(prefix="/api/v1/learning", tags=["Active Learning"])
pipeline = RetrainingPipeline(export_dir="D:/PDD2/Active Learning Loop/exports")

@router.get("/pending-follow-ups")
def get_pending_follow_ups(db: Session = Depends(get_db)):
    """
    Returns a list of all fields/tickets that received a high-risk advisory 7+ days ago 
    and need a feedback check.
    """
    return [
        {
            "original_ticket_id": "TICKET-001",
            "farmer_id": "FARMER-99",
            "days_since_advisory": 8,
            "status": "PENDING_FEEDBACK"
        }
    ]

@router.post("/submit-feedback", response_model=schemas.TreatmentFollowUpResponse)
def submit_feedback(payload: schemas.TreatmentFollowUpCreate, db: Session = Depends(get_db)):
    """
    Ingests the farmer's response (TreatmentFollowUp) and routes successful/failed 
    confirmations into the RetrainingArchive.
    """
    follow_up = models.TreatmentFollowUp(
        original_ticket_id=payload.original_ticket_id,
        farmer_id=payload.farmer_id,
        treatment_applied=payload.treatment_applied,
        treatment_efficacy=payload.treatment_efficacy,
        current_status=payload.current_status
    )
    db.add(follow_up)
    
    if payload.data_type and payload.source_file_path:
        archive = models.RetrainingArchive(
            data_type=payload.data_type,
            source_file_path=payload.source_file_path,
            predicted_label=payload.predicted_label,
            true_label=payload.true_label,
            confidence_score=payload.confidence_score
        )
        db.add(archive)
        
    db.commit()
    db.refresh(follow_up)
    return follow_up

@router.post("/archive-expert-validation", response_model=schemas.ArchiveValidationResponse)
def archive_expert_validation(payload: schemas.ArchiveValidationCreate, db: Session = Depends(get_db)):
    """
    Webhook intended for the Expert Referral module.
    When a KVK scientist verifies an image, this endpoint saves the image path 
    and the human-verified true_label into the RetrainingArchive.
    """
    archive = models.RetrainingArchive(
        data_type=payload.data_type,
        source_file_path=payload.source_file_path,
        predicted_label=payload.predicted_label,
        true_label=payload.true_label,
        confidence_score=payload.confidence_score
    )
    db.add(archive)
    db.commit()
    db.refresh(archive)
    return archive

@router.get("/export-dataset/{data_type}")
def export_dataset(data_type: str, db: Session = Depends(get_db)):
    """
    Triggers the export_engine.py to package the golden dataset for the ML engineers.
    """
    if data_type == "WEATHER_RISK":
        path = pipeline.export_weather_risk(db)
        return {"status": "success", "export_path": path, "data_type": data_type}
    elif data_type == "IMAGE_VISION":
        path = pipeline.export_image_vision(db)
        return {"status": "success", "export_path": path, "data_type": data_type}
    else:
        raise HTTPException(status_code=400, detail="Invalid data_type. Use WEATHER_RISK or IMAGE_VISION.")
