from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import requests

from admin_db import get_db, models
import schemas

router = APIRouter(prefix="/api/v1/admin/triage", tags=["Triage"])

@router.get("/tickets", response_model=List[schemas.ReferralTicketResponse])
def get_tickets(
    status: Optional[str] = None,
    crop: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(models.ReferralTicket)
    if status:
        query = query.filter(models.ReferralTicket.status == status)
    if crop:
        query = query.filter(models.ReferralTicket.crop_name == crop)
        
    tickets = query.order_by(models.ReferralTicket.created_at.desc()).offset(skip).limit(limit).all()
    return tickets

@router.get("/tickets/{ticket_id}", response_model=schemas.ReferralTicketResponse)
def get_ticket(ticket_id: int, db: Session = Depends(get_db)):
    ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket

@router.post("/tickets/{ticket_id}/action")
def process_ticket_action(ticket_id: int, action: schemas.TicketActionCreate, db: Session = Depends(get_db)):
    ticket = db.query(models.ReferralTicket).filter(models.ReferralTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # Update ticket status based on action
    if action.action_type == schemas.ActionType.CLOSE_TICKET:
        ticket.status = "CLOSED"
    elif action.action_type == schemas.ActionType.REQUEST_PHYSICAL_SAMPLE:
        ticket.status = "SAMPLE_SUBMISSION_REQUIRED"
    elif action.action_type == schemas.ActionType.SEND_ADVISORY:
        ticket.status = "EXPERT_DIAGNOSED"

    # Create Expert Review
    review = models.ExpertReview(
        ticket_id=ticket.id,
        expert_name=action.expert_name,
        expert_designation="KVK Official",
        confirmed_diagnosis=action.confirmed_diagnosis,
        custom_advisory=action.advisory_notes,
        require_physical_sample=(action.action_type == schemas.ActionType.REQUEST_PHYSICAL_SAMPLE),
        is_ai_accurate=not action.override_ai
    )
    db.add(review)

    # Trigger Active Learning Loop via Webhook if AI was overridden
    if action.override_ai:
        try:
            # We call the Learning loop running on port 8000
            webhook_payload = {
                "data_type": "IMAGE_VISION",
                "source_file_path": ticket.image_url or "N/A",
                "predicted_label": ticket.ai_prediction,
                "true_label": action.confirmed_diagnosis,
                "confidence_score": ticket.ai_confidence
            }
            requests.post("http://127.0.0.1:8000/api/v1/learning/archive-expert-validation", json=webhook_payload)
        except Exception as e:
            print(f"Warning: Failed to trigger active learning webhook: {e}")

    # Trigger Notification Webhook to main backend
    try:
        notification_payload = {
            "ticket_id": ticket.id,
            "status": ticket.status,
            "message": f"Your ticket #{ticket.id} has been updated to {ticket.status}."
        }
        requests.post("http://127.0.0.1:8000/api/v1/referral/internal/notify", json=notification_payload)
    except Exception as e:
        print(f"Warning: Failed to trigger notification webhook: {e}")

    db.commit()
    return {"status": "success", "message": "Action applied successfully"}
