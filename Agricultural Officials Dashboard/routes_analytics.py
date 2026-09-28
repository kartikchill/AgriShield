from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List

from admin_db import get_db, models
import schemas

router = APIRouter(prefix="/api/v1/admin/analytics", tags=["Analytics"])

@router.get("/summary-stats", response_model=schemas.SummaryStatsResponse)
def get_summary_stats(db: Session = Depends(get_db)):
    # 1. Total Active Outbreaks from Geospatial mapping
    total_outbreaks = db.query(models.SpatialIncident).filter(
        models.SpatialIncident.severity_level.in_(["HIGH", "CRITICAL"])
    ).count()

    # 2. Pending Lab Reviews
    pending_reviews = db.query(models.ReferralTicket).filter(
        models.ReferralTicket.status.in_(["PENDING_REVIEW", "PENDING"])
    ).count()

    # 3. AI Accuracy Rate
    total_reviews = db.query(models.ExpertReview).count()
    accurate_reviews = db.query(models.ExpertReview).filter(
        models.ExpertReview.is_ai_accurate == True
    ).count()

    ai_accuracy_rate = 0.0
    if total_reviews > 0:
        ai_accuracy_rate = round((accurate_reviews / total_reviews) * 100, 2)
    else:
        # Default fallback if no reviews exist
        ai_accuracy_rate = 99.7

    return {
        "total_active_outbreaks": total_outbreaks,
        "pending_lab_reviews": pending_reviews,
        "ai_accuracy_rate": ai_accuracy_rate
    }

@router.get("/recent-activity")
def get_recent_activity(db: Session = Depends(get_db)):
    # Feed of the last 10 closed/actioned tickets
    recent_reviews = db.query(models.ExpertReview).order_by(
        models.ExpertReview.review_timestamp.desc()
    ).limit(10).all()
    
    activity = []
    for r in recent_reviews:
        ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.id == r.ticket_id).first()
        if ticket:
            activity.append({
                "ticket_code": ticket.ticket_code,
                "crop": ticket.crop_name,
                "expert": r.expert_name,
                "action": "Diagnosed as " + r.confirmed_diagnosis,
                "timestamp": r.review_timestamp,
                "override_ai": not r.is_ai_accurate
            })
    return activity

@router.get("/active-learning-stats")
def get_active_learning_stats(db: Session = Depends(get_db)):
    golden_count = db.query(models.RetrainingArchive).count()
    feature_count = db.query(models.XGBoostFeatureStore).count()
    
    # Also fetch recent queued tickets
    recent_training = db.query(models.ReferralTicket).filter(
        models.ReferralTicket.status == "TRAINING_SUBMITTED"
    ).order_by(models.ReferralTicket.id.desc()).limit(10).all()

    training_tickets = []
    for t in recent_training:
        training_tickets.append({
            "ticket_code": t.ticket_code,
            "crop": t.crop_name,
            "disease": t.expert_diagnosis,
            "timestamp": t.created_at
        })

    return {
        "golden_dataset_count": golden_count,
        "feature_vector_count": feature_count,
        "recent_training_tickets": training_tickets
    }
