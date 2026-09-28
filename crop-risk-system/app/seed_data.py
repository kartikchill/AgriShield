from sqlalchemy.orm import Session
from .models import ETLThreshold

def seed_etl_thresholds(db: Session):
    # Check if data already exists
    if db.query(ETLThreshold).first():
        return
        
    # We want to support all combinations in the UI for the demo
    crops = ['Cotton', 'Soybean', 'Maize', 'Rice', 'Wheat', 'Tomato']
    pests = {
        'Fall Armyworm': {'etl_value': 10.0, 'unit': '% damage', 'action_advisory': 'ETL breached. Apply Emamectin benzoate 5% SG @ 0.4 g/L.'},
        'Pink Bollworm': {'etl_value': 8.0, 'unit': 'larvae/100 plants', 'action_advisory': 'Release Trichogramma egg parasitoids @ 1.5 lakh/ha.'},
        'Whitefly': {'etl_value': 15.0, 'unit': 'insects/leaf', 'action_advisory': 'Severe infestation. Use Diafenthiuron 50 WP.'},
        'Thrips': {'etl_value': 10.0, 'unit': 'insects/leaf', 'action_advisory': 'ETL crossed. Spray Spinosad 45 SC.'},
        'Stem Borer': {'etl_value': 10.0, 'unit': '% dead hearts', 'action_advisory': 'Apply Cartap hydrochloride 4G @ 25 kg/ha.'},
        'Aphids': {'etl_value': 12.0, 'unit': 'aphids/tiller', 'action_advisory': 'Conserve natural predators. Spray Dimethoate 30% EC.'}
    }
    
    thresholds = []
    for c in crops:
        for p_name, p_data in pests.items():
            thresholds.append({
                "crop_name": c,
                "pest_name": p_name,
                "metric_type": "count", # Universal metric for the numeric input
                "etl_value": p_data['etl_value'],
                "unit": p_data['unit'],
                "action_advisory": p_data['action_advisory']
            })
    
    for t in thresholds:
        db_threshold = ETLThreshold(**t)
        db.add(db_threshold)
        
    db.commit()

def seed_ipm_advisory_matrix(db: Session):
    from .models import IPMAdvisoryMatrix
    if db.query(IPMAdvisoryMatrix).first():
        return
        
    matrix = [
        {
            "crop_name": "Tomato",
            "pest_name": "Late Blight",
            "cultural_advisory": "Improve field drainage, increase plant spacing, remove infected lower leaves.",
            "biological_advisory": "Spray Pseudomonas fluorescens @ 5g/L.",
            "chemical_name": "Mancozeb 75% WP",
            "dosage_per_liter": 2.0,
            "required_ppe": "Chemical-resistant gloves, respirator mask, goggles.",
            "phi_days": 5,
            "re_entry_interval_hours": 24
        },
        {
            "crop_name": "Cotton",
            "pest_name": "Pink Bollworm",
            "cultural_advisory": "Deep summer ploughing, install yellow sticky traps.",
            "biological_advisory": "Release Trichogramma egg parasitoids @ 1.5 lakh/ha.",
            "chemical_name": "Chlorpyrifos 20% EC",
            "dosage_per_liter": 2.5,
            "required_ppe": "Long-sleeved clothing, gloves, mask.",
            "phi_days": 15,
            "re_entry_interval_hours": 48
        },
        {
            "crop_name": "Maize",
            "pest_name": "Fall Armyworm",
            "cultural_advisory": "Clean cultivation, early planting.",
            "biological_advisory": "Apply Bacillus thuringiensis (Bt) formulations.",
            "chemical_name": "Emamectin benzoate 5% SG",
            "dosage_per_liter": 0.4,
            "required_ppe": "Gloves, mask, protective eyewear.",
            "phi_days": 10,
            "re_entry_interval_hours": 24
        },
        {
            "crop_name": "Rice",
            "pest_name": "Stem Borer",
            "cultural_advisory": "Clip seedling tips before transplanting.",
            "biological_advisory": "Use pheromone traps @ 20/ha.",
            "chemical_name": "Chlorantraniliprole 18.5% SC",
            "dosage_per_liter": 0.3,
            "required_ppe": "Gloves, goggles.",
            "phi_days": 20,
            "re_entry_interval_hours": 12
        },
        {
            "crop_name": "Rice",
            "pest_name": "Brown Planthopper",
            "cultural_advisory": "Drain standing field water for 3-4 days.",
            "biological_advisory": "Conserve spiders and mirid bugs.",
            "chemical_name": "Dinotefuran 20% SG",
            "dosage_per_liter": 1.0,
            "required_ppe": "Gloves, mask.",
            "phi_days": 10,
            "re_entry_interval_hours": 12
        },
        {
            "crop_name": "Wheat",
            "pest_name": "Aphids",
            "cultural_advisory": "Avoid excess nitrogen fertilizer.",
            "biological_advisory": "Conserve Coccinellid beetles.",
            "chemical_name": "Dimethoate 30% EC",
            "dosage_per_liter": 1.0,
            "required_ppe": "Gloves, mask, long sleeves.",
            "phi_days": 14,
            "re_entry_interval_hours": 48
        }
    ]
    
    for item in matrix:
        db_item = IPMAdvisoryMatrix(**item)
        db.add(db_item)
    db.commit()

def seed_diagnostic_labs(db: Session):
    from .models import DiagnosticLab
    if db.query(DiagnosticLab).first():
        return

    labs_data = [
        {
            "name": "KVK Pune (Narayangaon) - ICAR",
            "district": "Pune",
            "state": "Maharashtra",
            "latitude": 19.1235,
            "longitude": 73.9780,
            "contact_email": "kvk.pune@icar.gov.in",
            "contact_phone": "+91-20-25691234",
            "address": "Krishi Vigyan Kendra, Narayangaon, Pune, Maharashtra"
        },
        {
            "name": "KVK Baramati (Sharadanagar)",
            "district": "Pune",
            "state": "Maharashtra",
            "latitude": 18.1528,
            "longitude": 74.5772,
            "contact_email": "kvkbaramati@yahoo.com",
            "contact_phone": "+91-2112-255227",
            "address": "Sharadanagar, Malegaon Colony, Baramati, Maharashtra"
        },
        {
            "name": "KVK Nashik (YCMOU)",
            "district": "Nashik",
            "state": "Maharashtra",
            "latitude": 19.9975,
            "longitude": 73.7898,
            "contact_email": "kvk.nashik@icar.gov.in",
            "contact_phone": "+91-253-2231011",
            "address": "Yashwantrao Chavan Maharashtra Open University Campus, Nashik, Maharashtra"
        },
        {
            "name": "KVK Akola (Dr. PDKV)",
            "district": "Akola",
            "state": "Maharashtra",
            "latitude": 20.7002,
            "longitude": 77.0082,
            "contact_email": "kvk.akola@pdkv.ac.in",
            "contact_phone": "+91-724-2258111",
            "address": "Dr. Panjabrao Deshmukh Krishi Vidyapeeth, Akola, Maharashtra"
        },
        {
            "name": "KVK Aurangabad / Chhatrapati Sambhaji Nagar",
            "district": "Aurangabad",
            "state": "Maharashtra",
            "latitude": 19.8762,
            "longitude": 75.3433,
            "contact_email": "kvkaurangabad@gmail.com",
            "contact_phone": "+91-240-2371234",
            "address": "CSMSS Krishi Vigyan Kendra, Kanchanwadi, Chhatrapati Sambhaji Nagar, Maharashtra"
        }
    ]

    for lab_dict in labs_data:
        db_lab = DiagnosticLab(**lab_dict)
        db.add(db_lab)
    db.commit()

def seed_hotspots(db: Session):
    from .models import SpatialIncident
    import random
    from datetime import datetime, timedelta

    if db.query(SpatialIncident).first():
        return

    now = datetime.utcnow()

    # Pre-populate realistic incident clusters across Maharashtra
    clusters = [
        # Nashik / Niphad (Grape & Tomato Belt) - CRITICAL
        {"district": "Nashik", "taluka": "Niphad", "lat_base": 20.0300, "lon_base": 73.9500, "crop": "Tomato", "pest": "Late Blight", "severity": "CRITICAL", "type": "WEATHER_RISK", "count": 15},
        # Akola / Yavatmal (Cotton Belt) - HIGH
        {"district": "Akola", "taluka": "Akola", "lat_base": 20.7000, "lon_base": 77.0000, "crop": "Cotton", "pest": "Pink Bollworm", "severity": "HIGH", "type": "ETL_BREACH", "count": 8},
        {"district": "Yavatmal", "taluka": "Yavatmal", "lat_base": 20.3800, "lon_base": 78.1200, "crop": "Cotton", "pest": "Pink Bollworm", "severity": "HIGH", "type": "ETL_BREACH", "count": 6},
        # Pune / Baramati (Sugarcane & Maize) - MEDIUM/HIGH
        {"district": "Pune", "taluka": "Baramati", "lat_base": 18.1500, "lon_base": 74.5700, "crop": "Maize", "pest": "Fall Armyworm", "severity": "MEDIUM", "type": "ETL_BREACH", "count": 10},
        # Kolhapur / Sangli (Rice & Sugarcane) - LOW/MEDIUM
        {"district": "Kolhapur", "taluka": "Karveer", "lat_base": 16.7000, "lon_base": 74.2400, "crop": "Rice", "pest": "Stem Borer", "severity": "MEDIUM", "type": "EXPERT_CONFIRMED", "count": 5},
        # Solapur (Pomegranate / Onion) - HIGH
        {"district": "Solapur", "taluka": "North Solapur", "lat_base": 17.6500, "lon_base": 75.9000, "crop": "Pomegranate", "pest": "Bacterial Blight", "severity": "HIGH", "type": "EXPERT_CONFIRMED", "count": 7},
    ]

    severity_weights = {"LOW": 0.3, "MEDIUM": 0.6, "HIGH": 0.85, "CRITICAL": 0.98}

    for c in clusters:
        for _ in range(c["count"]):
            lat_offset = random.uniform(-0.05, 0.05)
            lon_offset = random.uniform(-0.05, 0.05)
            time_offset = timedelta(days=random.uniform(0, 7), hours=random.uniform(0, 24))
            
            incident = SpatialIncident(
                incident_type=c["type"],
                crop_name=c["crop"],
                pathogen_pest=c["pest"],
                severity_level=c["severity"],
                risk_score=severity_weights[c["severity"]] * random.uniform(0.9, 1.1),
                latitude=c["lat_base"] + lat_offset,
                longitude=c["lon_base"] + lon_offset,
                district=c["district"],
                taluka=c["taluka"],
                timestamp=now - time_offset
            )
            db.add(incident)
    
    db.commit()
