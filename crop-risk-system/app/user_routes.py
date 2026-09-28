from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from . import models
from .database import get_db
from .localization.engine import translator

router = APIRouter()

class LocaleUpdateRequest(BaseModel):
    locale: str

@router.patch("/api/v1/users/locale")
def update_user_locale(
    req: LocaleUpdateRequest,
    phone_number: str = "9876543210", # Mock authentication
    db: Session = Depends(get_db)
):
    profile = db.query(models.FarmerProfile).filter(models.FarmerProfile.phone_number == phone_number).first()
    if not profile:
        profile = models.FarmerProfile(phone_number=phone_number, preferred_locale=req.locale)
        db.add(profile)
    else:
        profile.preferred_locale = req.locale
    db.commit()
    return {"status": "success", "locale": req.locale}

@router.get("/api/v1/sync")
def sync_data(
    phone_number: str = "9876543210", # Mock authentication
    accept_language: str = Header(default="en"),
    db: Session = Depends(get_db)
):
    tickets = db.query(models.ReferralTicket).filter(models.ReferralTicket.phone_number == phone_number).all()
    
    lang = accept_language.split(",")[0].split("-")[0].lower()

    def t_str(text: str) -> str:
        if not text: return text
        key = translator._map_to_key(text)
        if key: return translator.get_text(key, lang)
        return text

    sync_response = []
    for t in tickets:
        expert_diagnosis = None
        expert_advisory = None
        
        # Get the latest expert review if it exists
        if t.reviews:
            latest_review = sorted(t.reviews, key=lambda r: r.review_timestamp, reverse=True)[0]
            expert_diagnosis = latest_review.confirmed_diagnosis
            expert_advisory = latest_review.custom_advisory

        sync_response.append({
            "ticket_code": t.ticket_code,
            "status": t.status,
            "expert_diagnosis": t_str(expert_diagnosis) if expert_diagnosis else None,
            "expert_advisory": t_str(expert_advisory) if expert_advisory else None
        })
        
    return {"tickets": sync_response}
