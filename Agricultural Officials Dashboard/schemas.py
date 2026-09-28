from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ActionType(str, Enum):
    SEND_ADVISORY = "SEND_ADVISORY"
    REQUEST_PHYSICAL_SAMPLE = "REQUEST_PHYSICAL_SAMPLE"
    CLOSE_TICKET = "CLOSE_TICKET"

class TicketActionCreate(BaseModel):
    expert_name: str
    confirmed_diagnosis: str
    advisory_notes: str
    override_ai: bool
    action_type: ActionType

class ReferralTicketResponse(BaseModel):
    id: int
    ticket_code: str
    farmer_name: str
    phone_number: str
    crop_name: str
    reported_symptoms: str
    image_url: Optional[str]
    ai_prediction: str
    ai_confidence: float
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class SummaryStatsResponse(BaseModel):
    total_active_outbreaks: int
    pending_lab_reviews: int
    ai_accuracy_rate: float
