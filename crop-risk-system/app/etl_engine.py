from sqlalchemy.orm import Session
import json
from .models import ETLThreshold, SensorTrapLog, IPMAdvisoryMatrix
from .schemas import SensorLogCreate

def evaluate_pest_risk(db: Session, log_data: SensorLogCreate):
    # 1. Fetch matching ETL threshold
    threshold = db.query(ETLThreshold).filter(
        ETLThreshold.crop_name.ilike(log_data.crop_name),
        ETLThreshold.pest_name.ilike(log_data.pest_name),
        ETLThreshold.metric_type.ilike(log_data.metric_type)
    ).first()
    
    if not threshold:
        status = "UNKNOWN"
        advisory_text = "No official ICAR threshold found."
    else:
        obs_val = log_data.observed_value
        etl_val = threshold.etl_value
        if obs_val >= etl_val:
            status = "ETL_BREACH"
            advisory_text = f"High Risk - Action Required: {threshold.action_advisory}"
        elif obs_val >= 0.7 * etl_val:
            status = "MONITOR"
            advisory_text = "Moderate Risk - Scout field every 48 hours."
        else:
            status = "SAFE"
            advisory_text = "Low Risk - Pest density below economic damage levels."
            
    # Fetch IPM Advisory Matrix
    ipm = db.query(IPMAdvisoryMatrix).filter(
        IPMAdvisoryMatrix.crop_name.ilike(log_data.crop_name),
        IPMAdvisoryMatrix.pest_name.ilike(log_data.pest_name)
    ).first()
    
    ipm_response = None
    if ipm:
        ipm_response = {
            "cultural_advisory": ipm.cultural_advisory
        }
        if status in ["MONITOR", "ETL_BREACH"]:
            ipm_response["biological_advisory"] = ipm.biological_advisory
        if status == "ETL_BREACH":
            ipm_response["chemical_name"] = ipm.chemical_name
            ipm_response["dosage_per_liter"] = ipm.dosage_per_liter
            ipm_response["required_ppe"] = ipm.required_ppe
            ipm_response["phi_days"] = ipm.phi_days
            ipm_response["re_entry_interval_hours"] = ipm.re_entry_interval_hours

    # 3. Create log entry
    db_log = SensorTrapLog(
        field_id=log_data.field_id,
        farmer_id=log_data.farmer_id,
        crop_name=log_data.crop_name,
        pest_name=log_data.pest_name,
        metric_type=log_data.metric_type,
        observed_value=log_data.observed_value,
        latitude=log_data.latitude,
        longitude=log_data.longitude,
        status=status,
        advisory=json.dumps(ipm_response) if ipm_response else advisory_text
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    
    # Attach for Pydantic response
    setattr(db_log, "ipm_advisory", ipm_response)
    # Put text back so it shows nicely instead of raw JSON
    db_log.advisory = advisory_text 
    
    return db_log
