from pydantic import BaseModel, Json, AnyHttpUrl
from typing import List, Optional, Any, Dict
from datetime import datetime

class IPMAdvisoryResponse(BaseModel):
    cultural_advisory: Optional[str] = None
    biological_advisory: Optional[str] = None
    chemical_name: Optional[str] = None
    dosage_per_liter: Optional[float] = None
    required_ppe: Optional[str] = None
    phi_days: Optional[int] = None
    re_entry_interval_hours: Optional[int] = None

class AssessRiskRequest(BaseModel):
    crop_type: str
    crop_variety: str
    growth_stage: str
    soil_type: str
    latitude: float
    longitude: float

class ForecastDay(BaseModel):
    day: str
    risk: float
    level: str
    temp: float
    humidity: float
    rain: float

class ExplanationBreakdown(BaseModel):
    field_metrics: str
    required_thresholds: str
    citation: str

class DiseaseRisk(BaseModel):
    disease_name: str
    risk_level: str
    score: float
    explanation_breakdown: ExplanationBreakdown

class AssessRiskResponse(BaseModel):
    field_id: int
    diseases: List[DiseaseRisk]
    summary: str
    forecast: List[ForecastDay]
    recommendation: str
    ipm_advisory: Optional[IPMAdvisoryResponse] = None

class SensorLogCreate(BaseModel):
    field_id: str
    farmer_id: Optional[str] = "unknown"
    crop_name: str
    pest_name: str
    metric_type: str
    observed_value: float
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class SensorLogResponse(BaseModel):
    id: int
    field_id: str
    crop_name: str
    pest_name: str
    metric_type: str
    observed_value: float
    status: str
    advisory: str
    ipm_advisory: Optional[IPMAdvisoryResponse] = None
    timestamp: datetime
    
    class Config:
        from_attributes = True

class ETLThresholdResponse(BaseModel):
    id: int
    crop_name: str
    pest_name: str
    metric_type: str
    etl_value: float
    unit: str
    action_advisory: str
    
    class Config:
        from_attributes = True

# --- EXPERT REFERRAL SCHEMAS ---
class DiagnosticLabResponse(BaseModel):
    id: int
    name: str
    district: str
    state: str
    latitude: float
    longitude: float
    contact_email: str
    contact_phone: str
    address: str

    class Config:
        from_attributes = True

class TicketCreate(BaseModel):
    farmer_name: str
    phone_number: str
    field_id: str
    crop_name: str
    reported_symptoms: str
    image_url: Optional[str] = None
    ai_prediction: str
    ai_confidence: float
    latitude: float
    longitude: float

class TicketResponse(BaseModel):
    id: int
    ticket_code: str
    farmer_name: str
    phone_number: str
    field_id: str
    crop_name: str
    reported_symptoms: str
    image_url: Optional[str] = None
    ai_prediction: str
    ai_confidence: float
    assigned_lab_id: int
    status: str
    created_at: datetime
    lab: Optional[DiagnosticLabResponse] = None

    class Config:
        from_attributes = True

class ExpertReviewCreate(BaseModel):
    expert_name: str
    expert_designation: str
    confirmed_diagnosis: str
    custom_advisory: str
    require_physical_sample: bool
    is_ai_accurate: bool

class ExpertReviewResponse(BaseModel):
    id: int
    ticket_id: int
    expert_name: str
    expert_designation: str
    confirmed_diagnosis: str
    custom_advisory: str
    require_physical_sample: bool
    is_ai_accurate: bool
    review_timestamp: datetime

    class Config:
        from_attributes = True

class TicketDetailResponse(TicketResponse):
    reviews: List[ExpertReviewResponse] = []
    
    class Config:
        from_attributes = True

# --- GEOSPATIAL HOTSPOT SCHEMAS ---
class IncidentLogRequest(BaseModel):
    incident_type: str
    crop_name: str
    pathogen_pest: str
    severity_level: str
    risk_score: float
    latitude: float
    longitude: float
    district: str
    taluka: str

class DistrictSummaryResponse(BaseModel):
    district: str
    active_outbreaks: int
    dominant_pathogen: Optional[str]
    alert_status: str
    last_updated: datetime

    class Config:
        from_attributes = True



class TreatmentFollowUpCreate(BaseModel):
    original_ticket_id: str
    farmer_id: str
    treatment_applied: str
    treatment_efficacy: str
    current_status: str
    
    # Optional fields for routing data into the AI Retraining Archive
    data_type: Optional[str] = None
    source_file_path: Optional[str] = None
    predicted_label: Optional[str] = None
    true_label: Optional[str] = None
    confidence_score: Optional[float] = None

class TreatmentFollowUpResponse(BaseModel):
    id: int
    original_ticket_id: str
    farmer_id: str
    treatment_applied: str
    treatment_efficacy: str
    current_status: str
    follow_up_date: datetime

    class Config:
        from_attributes = True

class ArchiveValidationCreate(BaseModel):
    data_type: str
    source_file_path: str
    predicted_label: str
    true_label: str
    confidence_score: float

class ArchiveValidationResponse(ArchiveValidationCreate):
    id: int
    added_on: datetime

    class Config:
        from_attributes = True
