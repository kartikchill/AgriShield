from fastapi import APIRouter, HTTPException
from typing import Optional
from datetime import datetime
import json, os

router = APIRouter(prefix="/api/insurance", tags=["Insurance"])

CLAIMS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "insurance_claims.json")

def _load_claims():
    if os.path.exists(CLAIMS_FILE):
        with open(CLAIMS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return [
        {"id": 1, "farmer_name": "Rajesh Patil", "phone": "9876543210", "crop": "Cotton", "damage_type": "Pest Damage", "district": "Nashik", "scheme": "PMFBY", "status": "PENDING", "submitted_at": "2026-09-20T10:00:00", "claim_amount": 45000, "notes": "Fall Armyworm damage on 5 acres"},
        {"id": 2, "farmer_name": "Sunita Shinde", "phone": "9823456781", "crop": "Soybean", "damage_type": "Excess Rain", "district": "Pune", "scheme": "RWBCIS", "status": "APPROVED", "submitted_at": "2026-09-18T14:30:00", "claim_amount": 30000, "notes": "Heavy rain caused waterlogging"},
        {"id": 3, "farmer_name": "Mahesh Jadhav", "phone": "9765432100", "crop": "Wheat", "damage_type": "Drought", "district": "Aurangabad", "scheme": "SDRF", "status": "UNDER_REVIEW", "submitted_at": "2026-09-22T09:15:00", "claim_amount": 55000, "notes": "Severe drought 8 acres"},
    ]

def _save_claims(claims):
    with open(CLAIMS_FILE, "w", encoding="utf-8") as f:
        json.dump(claims, f, indent=2, ensure_ascii=False)

@router.get("/claims")
def get_claims(status: Optional[str] = None):
    claims = _load_claims()
    if status and status != "ALL":
        claims = [c for c in claims if c["status"] == status]
    return claims

@router.get("/claims/{claim_id}")
def get_claim(claim_id: int):
    claims = _load_claims()
    claim = next((c for c in claims if c["id"] == claim_id), None)
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    return claim

@router.post("/claims")
def create_claim(data: dict):
    claims = _load_claims()
    new_id = max((c["id"] for c in claims), default=0) + 1
    claim = {"id": new_id, "farmer_name": data.get("farmer_name", ""), "phone": data.get("phone", ""), "crop": data.get("crop", ""), "damage_type": data.get("damage_type", ""), "district": data.get("district", ""), "scheme": data.get("scheme", "PMFBY"), "status": "PENDING", "submitted_at": datetime.now().isoformat(), "claim_amount": data.get("claim_amount", 0), "notes": data.get("notes", "")}
    claims.append(claim)
    _save_claims(claims)
    return claim

@router.patch("/claims/{claim_id}/status")
def update_claim_status(claim_id: int, data: dict):
    claims = _load_claims()
    claim = next((c for c in claims if c["id"] == claim_id), None)
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    claim["status"] = data.get("status", claim["status"])
    claim["notes"] = data.get("notes", claim.get("notes", ""))
    _save_claims(claims)
    return claim

@router.get("/schemes")
def get_schemes():
    return [
        {"id": "PMFBY", "name": "Pradhan Mantri Fasal Bima Yojana", "coverage": "Standard crop damage, pests, localized disasters", "deadline_hours": 72},
        {"id": "RWBCIS", "name": "Weather Based Crop Insurance Scheme", "coverage": "Unseasonal rain, frost, hail", "deadline_hours": 48},
        {"id": "SDRF", "name": "State Disaster Relief Fund", "coverage": "Floods, droughts, cyclones", "deadline_hours": 120},
    ]
