from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from .models import SpatialIncident, DistrictSummary
import json

def get_heatmap_points(db: Session, days_back: int = 14):
    cutoff_date = datetime.utcnow() - timedelta(days=days_back)
    incidents = db.query(SpatialIncident).filter(SpatialIncident.timestamp >= cutoff_date).all()
    
    # Returns [lat, lng, intensity] for leaflet-heat
    points = []
    for inc in incidents:
        # cap risk score at 1.0 for rendering
        intensity = min(1.0, inc.risk_score)
        points.append([inc.latitude, inc.longitude, intensity])
        
    return points

def get_geojson_points(db: Session, days_back: int = 14):
    cutoff_date = datetime.utcnow() - timedelta(days=days_back)
    incidents = db.query(SpatialIncident).filter(SpatialIncident.timestamp >= cutoff_date).all()
    
    features = []
    for inc in incidents:
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [inc.longitude, inc.latitude] # GeoJSON uses [lon, lat]
            },
            "properties": {
                "id": inc.id,
                "incident_type": inc.incident_type,
                "crop": inc.crop_name,
                "pathogen": inc.pathogen_pest,
                "severity": inc.severity_level,
                "district": inc.district,
                "date": inc.timestamp.isoformat()
            }
        })
        
    return {
        "type": "FeatureCollection",
        "features": features
    }

def update_district_summaries(db: Session):
    cutoff_date = datetime.utcnow() - timedelta(days=14)
    
    # Get counts per district and pathogen
    results = db.query(
        SpatialIncident.district, 
        SpatialIncident.pathogen_pest, 
        func.count(SpatialIncident.id).label('count')
    ).filter(SpatialIncident.timestamp >= cutoff_date) \
     .group_by(SpatialIncident.district, SpatialIncident.pathogen_pest).all()
     
    districts_data = {}
    
    for district, pathogen, count in results:
        if district not in districts_data:
            districts_data[district] = {"total": 0, "pathogens": {}}
        districts_data[district]["total"] += count
        districts_data[district]["pathogens"][pathogen] = count
        
    # Update or Create Summaries
    for dist_name, data in districts_data.items():
        summary = db.query(DistrictSummary).filter(DistrictSummary.district == dist_name).first()
        if not summary:
            summary = DistrictSummary(district=dist_name)
            db.add(summary)
            
        summary.active_outbreaks = data["total"]
        
        # Find dominant pathogen
        dominant = max(data["pathogens"], key=data["pathogens"].get) if data["pathogens"] else "Unknown"
        summary.dominant_pathogen = dominant
        
        # Assign alert status
        if summary.active_outbreaks > 10:
            summary.alert_status = "CRITICAL"
        elif summary.active_outbreaks > 5:
            summary.alert_status = "WATCH"
        else:
            summary.alert_status = "NORMAL"
            
        summary.last_updated = datetime.utcnow()
        
    db.commit()

def get_district_summaries(db: Session):
    return db.query(DistrictSummary).order_by(DistrictSummary.active_outbreaks.desc()).all()
