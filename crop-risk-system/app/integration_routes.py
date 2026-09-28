from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional

router = APIRouter(prefix="/api/v1/integration", tags=["integration"])

@router.get("/shc")
def get_soil_health_card(lat: float = Query(...), lng: float = Query(...)):
    # Mock logic for registered zones (e.g., Maharashtra region roughly)
    if 15.0 <= lat <= 22.5 and 72.0 <= lng <= 81.0:
        if lat > 19.5:
            soil_type = "Black Cotton"
            ph_level = 7.2
            nitrogen_N = 120.5
            phosphorus_P = 45.2
            potassium_K = 210.0
            recommended_crops = ["Cotton", "Soybean", "Sorghum"]
        else:
            soil_type = "Alluvial"
            ph_level = 6.8
            nitrogen_N = 145.0
            phosphorus_P = 55.0
            potassium_K = 180.0
            recommended_crops = ["Wheat", "Rice", "Sugarcane"]
            
        return {
            "soil_type": soil_type,
            "ph_level": ph_level,
            "nitrogen_N": nitrogen_N,
            "phosphorus_P": phosphorus_P,
            "potassium_K": potassium_K,
            "recommended_crops": recommended_crops
        }
    else:
        raise HTTPException(status_code=404, detail="No official soil record found for this location.")
