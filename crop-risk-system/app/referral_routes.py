import json
import urllib.request
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import traceback

from .database import get_db
from . import models, schemas, geo_routing

router = APIRouter(prefix="/api/v1/referral", tags=["Expert Validation & Lab Referral"])

def notify_websocket(ticket_id: int, status: str, message: str):
    try:
        data = json.dumps({
            "ticket_id": ticket_id,
            "status": status,
            "message": message
        }).encode('utf-8')
        req = urllib.request.Request(
            "http://localhost:8000/api/v1/referral/internal/notify",
            data=data,
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        urllib.request.urlopen(req, timeout=2)
    except Exception as e:
        print(f"Failed to send websocket notification: {e}")
        traceback.print_exc()

@router.post("/create-ticket")
def create_referral_ticket(ticket: schemas.TicketCreate, db: Session = Depends(get_db)):
    print(f'DEBUG: image_url length: {len(ticket.image_url) if ticket.image_url else 0}', flush=True)
    nearest_lab, distance_km = geo_routing.get_nearest_lab(db, ticket.latitude, ticket.longitude)
    if not nearest_lab:
        raise HTTPException(status_code=500, detail="No diagnostic labs available in the system.")

    db_ticket = models.ReferralTicket(
        farmer_name=ticket.farmer_name,
        phone_number=ticket.phone_number,
        field_id=ticket.field_id,
        crop_name=ticket.crop_name,
        reported_symptoms=ticket.reported_symptoms,
        image_url=ticket.image_url,
        ai_prediction=ticket.ai_prediction,
        ai_confidence=ticket.ai_confidence,
        assigned_lab_id=nearest_lab.id,
        status="PENDING_REVIEW"
    )
    
    db.add(db_ticket)
    db.commit()
    db.refresh(db_ticket)

    notify_websocket(
        ticket_id=db_ticket.id, 
        status=db_ticket.status, 
        message=f"New ticket created: {db_ticket.ticket_code}"
    )

    return {
        "ticket_code": db_ticket.ticket_code,
        "assigned_lab": nearest_lab.name,
        "distance_km": round(distance_km, 2),
        "status": db_ticket.status,
        "packaging_guidelines": "1. Collect sample showing both healthy and diseased tissue. 2. Wrap in slightly damp paper towel. 3. Place in ventilated plastic bag. 4. Deliver within 24 hours.",
        "lab_contact": nearest_lab.contact_phone
    }

@router.get("/tickets/pending", response_model=List[schemas.TicketResponse])
def get_pending_tickets(db: Session = Depends(get_db)):
    tickets = db.query(models.ReferralTicket).filter(models.ReferralTicket.status == "PENDING_REVIEW").all()
    return tickets

@router.get("/tickets/all", response_model=List[schemas.TicketResponse])
def get_all_tickets(db: Session = Depends(get_db)):
    tickets = db.query(models.ReferralTicket).order_by(models.ReferralTicket.created_at.desc()).all()
    return tickets

@router.post("/review/{ticket_id}", response_model=schemas.ExpertReviewResponse)
def submit_expert_review(ticket_id: int, review: schemas.ExpertReviewCreate, db: Session = Depends(get_db)):
    ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    db_review = models.ExpertReview(
        ticket_id=ticket.id,
        expert_name=review.expert_name,
        expert_designation=review.expert_designation,
        confirmed_diagnosis=review.confirmed_diagnosis,
        custom_advisory=review.custom_advisory,
        require_physical_sample=review.require_physical_sample,
        is_ai_accurate=review.is_ai_accurate
    )

    ticket.status = "SAMPLE_SUBMISSION_REQUIRED" if review.require_physical_sample else "EXPERT_DIAGNOSED"
    
    db.add(db_review)
    db.commit()
    db.refresh(db_review)

    notify_websocket(
        ticket_id=ticket.id,
        status=ticket.status,
        message=f"Expert review submitted. Status: {ticket.status}"
    )

    return db_review

@router.get("/ticket-status/{ticket_code}", response_model=schemas.TicketDetailResponse)
def get_ticket_status(ticket_code: str, db: Session = Depends(get_db)):
    ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.ticket_code == ticket_code).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket

@router.put("/approve/{ticket_id}")
def approve_ticket(ticket_id: int, db: Session = Depends(get_db)):
    ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    ticket.status = "APPROVED"
    db.commit()
    
    notify_websocket(
        ticket_id=ticket.id,
        status=ticket.status,
        message=f"Your ticket {ticket.ticket_code} has been approved."
    )
    return {"status": "success", "ticket_id": ticket.id, "new_status": ticket.status}

from fastapi import WebSocket, WebSocketDisconnect

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                print(f"Broadcast error: {e}")

manager = ConnectionManager()

@router.websocket("/ws/notifications")
async def websocket_endpoint(websocket: WebSocket, token: str = None):
    # Await accept() immediately as requested
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@router.post("/internal/notify")
async def internal_notify(payload: dict):
    await manager.broadcast(json.dumps(payload))
    return {"status": "ok"}
