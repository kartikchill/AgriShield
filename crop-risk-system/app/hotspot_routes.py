from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Dict, Any

from .database import get_db
from . import schemas, spatial_engine, models

router = APIRouter(prefix="/api/v1/hotspots", tags=["Geospatial Hotspot Mapping"])

@router.get("/geojson", response_model=Dict[str, Any])
def get_geojson(days: int = 14, db: Session = Depends(get_db)):
    """Returns a GeoJSON FeatureCollection of all active incidents."""
    return spatial_engine.get_geojson_points(db, days_back=days)

@router.get("/heatmap-points", response_model=List[List[float]])
def get_heatmap_points(days: int = 14, db: Session = Depends(get_db)):
    """Returns raw coordinate arrays with intensity weights [[lat, lng, intensity], ...]."""
    return spatial_engine.get_heatmap_points(db, days_back=days)

@router.get("/district-summary", response_model=List[schemas.DistrictSummaryResponse])
def get_district_summary(db: Session = Depends(get_db)):
    """Returns aggregated tabular metrics per district."""
    # Ensure summaries are up to date
    spatial_engine.update_district_summaries(db)
    return spatial_engine.get_district_summaries(db)

@router.post("/log-incident")
def log_incident(request: schemas.IncidentLogRequest, db: Session = Depends(get_db)):
    """Ingests real-time risk alerts to keep the map updated."""
    incident = models.SpatialIncident(
        incident_type=request.incident_type,
        crop_name=request.crop_name,
        pathogen_pest=request.pathogen_pest,
        severity_level=request.severity_level,
        risk_score=request.risk_score,
        latitude=request.latitude,
        longitude=request.longitude,
        district=request.district,
        taluka=request.taluka
    )
    db.add(incident)
    db.commit()
    
    # Trigger background summary update
    spatial_engine.update_district_summaries(db)
    
    return {"status": "success", "incident_id": incident.id}
