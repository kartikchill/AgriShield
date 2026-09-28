import math
from .models import DiagnosticLab
from sqlalchemy.orm import Session


def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # Earth radius in kilometers
    R = 6371.0

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)

    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = R * c
    return distance

def get_nearest_lab(db: Session, farmer_lat: float, farmer_lon: float):
    labs = db.query(DiagnosticLab).all()
    if not labs:
        return None, 0.0

    closest_lab = None
    min_distance = float('inf')

    for lab in labs:
        dist = calculate_haversine_distance(farmer_lat, farmer_lon, lab.latitude, lab.longitude)
        if dist < min_distance:
            min_distance = dist
            closest_lab = lab

    return closest_lab, min_distance
