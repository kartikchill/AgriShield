from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from .database import Base

class Field(Base):
    __tablename__ = 'fields'
    id = Column(Integer, primary_key=True, index=True)
    farmer_name = Column(String, default='Farmer')
    crop_type = Column(String)
    crop_variety = Column(String)
    growth_stage = Column(String)
    soil_type = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

    assessments = relationship("RiskAssessment", back_populates="field")

class RiskAssessment(Base):
    __tablename__ = "risk_assessments"
    id = Column(Integer, primary_key=True, index=True)
    field_id = Column(Integer, ForeignKey("fields.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    disease_name = Column(String, default="Late Blight")
    current_risk_score = Column(Float)
    risk_level = Column(String)
    forecast_json = Column(Text)
    factors_json = Column(Text)
    avg_temp = Column(Float)
    avg_humidity = Column(Float)
    total_rainfall = Column(Float)

    field = relationship("Field", back_populates="assessments")

class ETLThreshold(Base):
    __tablename__ = "etl_thresholds"
    id = Column(Integer, primary_key=True, index=True)
    crop_name = Column(String, index=True)
    pest_name = Column(String, index=True)
    metric_type = Column(String)
    etl_value = Column(Float)
    unit = Column(String)
    action_advisory = Column(Text)

class SensorTrapLog(Base):
    __tablename__ = "sensor_trap_logs"
    id = Column(Integer, primary_key=True, index=True)
    field_id = Column(String, index=True)
    farmer_id = Column(String)
    crop_name = Column(String)
    pest_name = Column(String)
    metric_type = Column(String)
    observed_value = Column(Float)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    status = Column(String)
    advisory = Column(Text) # Will store serialized JSON now
    timestamp = Column(DateTime, default=datetime.utcnow)

class IPMAdvisoryMatrix(Base):
    __tablename__ = "ipm_advisory_matrix"
    id = Column(Integer, primary_key=True, index=True)
    crop_name = Column(String, index=True)
    pest_name = Column(String, index=True)
    cultural_advisory = Column(Text)
    biological_advisory = Column(Text)
    chemical_name = Column(String)
    dosage_per_liter = Column(Float)
    required_ppe = Column(Text)
    phi_days = Column(Integer)
    re_entry_interval_hours = Column(Integer)

# --- EXPERT REFERRAL MODELS ---
def generate_ticket_code():
    import uuid
    from datetime import datetime
    return f"TKT-MAH-{datetime.now().strftime('%Y')}-{str(uuid.uuid4())[:8].upper()}"
class FarmerProfile(Base):
    __tablename__ = "farmer_profiles"
    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, unique=True, index=True)
    preferred_locale = Column(String, default="en")

class DiagnosticLab(Base):
    __tablename__ = "diagnostic_labs"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    district = Column(String)
    state = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    contact_email = Column(String)
    contact_phone = Column(String)
    address = Column(Text)

class ReferralTicket(Base):
    __tablename__ = "referral_tickets"
    id = Column(Integer, primary_key=True, index=True)
    ticket_code = Column(String, unique=True, index=True, default=generate_ticket_code)
    farmer_name = Column(String)
    phone_number = Column(String)
    field_id = Column(String)
    crop_name = Column(String)
    reported_symptoms = Column(Text)
    image_url = Column(String, nullable=True)
    ai_prediction = Column(String)
    ai_confidence = Column(Float)
    
    assigned_lab_id = Column(Integer, ForeignKey("diagnostic_labs.id"))
    status = Column(String, default="PENDING_REVIEW") # PENDING_REVIEW, EXPERT_DIAGNOSED, SAMPLE_SUBMISSION_REQUIRED, CLOSED
    created_at = Column(DateTime, default=datetime.utcnow)

    lab = relationship("DiagnosticLab")
    reviews = relationship("ExpertReview", back_populates="ticket")

class ExpertReview(Base):
    __tablename__ = "expert_reviews"
    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("referral_tickets.id"))
    expert_name = Column(String)
    expert_designation = Column(String)
    confirmed_diagnosis = Column(String)
    custom_advisory = Column(Text)
    require_physical_sample = Column(Boolean)
    is_ai_accurate = Column(Boolean)
    review_timestamp = Column(DateTime, default=datetime.utcnow)

    ticket = relationship("ReferralTicket", back_populates="reviews")

# --- GEOSPATIAL HOTSPOT MODELS ---
class SpatialIncident(Base):
    __tablename__ = "spatial_incidents"
    id = Column(Integer, primary_key=True, index=True)
    incident_type = Column(String) # WEATHER_RISK, ETL_BREACH, EXPERT_CONFIRMED
    crop_name = Column(String)
    pathogen_pest = Column(String)
    severity_level = Column(String) # LOW, MEDIUM, HIGH, CRITICAL
    risk_score = Column(Float) # 0.0 to 1.0 intensity weight
    latitude = Column(Float)
    longitude = Column(Float)
    district = Column(String)
    taluka = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

class DistrictSummary(Base):
    __tablename__ = "district_summaries"
    id = Column(Integer, primary_key=True, index=True)
    district = Column(String, unique=True, index=True)
    active_outbreaks = Column(Integer, default=0)
    dominant_pathogen = Column(String, nullable=True)
    alert_status = Column(String, default="NORMAL") # NORMAL, WATCH, CRITICAL
    last_updated = Column(DateTime, default=datetime.utcnow)



from sqlalchemy import Float
class TreatmentFollowUp(Base):
    __tablename__ = "treatment_follow_ups"

    id = Column(Integer, primary_key=True, index=True)
    original_ticket_id = Column(String, index=True)
    farmer_id = Column(String, index=True)
    follow_up_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    treatment_applied = Column(String)
    treatment_efficacy = Column(String) # SUCCESS, PARTIAL, FAILED
    current_status = Column(String) # RESOLVED, ESCALATED

class RetrainingArchive(Base):
    __tablename__ = "retraining_archive"

    id = Column(Integer, primary_key=True, index=True)
    data_type = Column(String, index=True) # IMAGE_VISION, WEATHER_RISK
    source_file_path = Column(String)
    predicted_label = Column(String)
    true_label = Column(String)
    confidence_score = Column(Float)
    added_on = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class XGBoostFeatureStore(Base):
    __tablename__ = "xgboost_feature_store"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(String, index=True)
    crop = Column(String)
    disease = Column(String)
    temp_mean = Column(Float)
    rh_min = Column(Float)
    rh_max = Column(Float)
    rain_sum = Column(Float)
    p_days = Column(Float)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    


