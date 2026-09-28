"""
FastAPI Router — Model B Vision (Image-based Disease Identification)
Prefix: /api/v1/vision
"""
import sys
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse

# Allow importing vision_engine when running as standalone or from main app
sys.path.insert(0, str(Path(__file__).parent))
from vision_engine import vision_model

router = APIRouter(prefix="/api/v1/vision", tags=["Model B - Vision AI"])

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "application/octet-stream"}
MAX_FILE_SIZE_BYTES   = 10 * 1024 * 1024  # 10 MB


@router.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """
    Analyze a crop leaf image and return:
    - Predicted disease class + confidence
    - Top-3 predictions
    - Whether expert review is recommended (confidence < 70%)
    - IPM advisory lookup key (links to ETL system)

    Accepted formats: JPEG, PNG, WEBP  |  Max size: 10 MB
    """
    # ── Format validation ────────────────────────────────────────────────
    ct = (file.content_type or "").lower()
    if ct not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=(
                f"Unsupported file type: '{file.content_type}'. "
                f"Please upload a JPEG or PNG image."
            ),
        )

    # ── Read bytes ───────────────────────────────────────────────────────
    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    if len(image_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large ({len(image_bytes)//1024} KB). Maximum is 10 MB."
        )

    # ── Run inference ────────────────────────────────────────────────────
    try:
        result = vision_model.predict(image_bytes)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected inference error: {str(e)}"
        )

    # ── Build response ───────────────────────────────────────────────────
    response = {
        "model":          "Model B — EfficientNetV2-S (Plant Disease Vision AI)",
        "filename":       file.filename,
        "disease_class":  result["disease_class"],
        "display_name":   result["display_name"],
        "confidence":     result["confidence"],
        "confidence_pct": f"{result['confidence']*100:.1f}%",
        "is_healthy":     result["is_healthy"],
        "top3":           result["top3"],
        "ipm_lookup":     result["ipm_lookup"],
        # Triage flag — triggers referral ticket prompt in frontend
        "requires_expert_review": result["requires_expert_review"],
        "triage_message": (
            "⚠️ Low confidence prediction. We recommend escalating to a lab expert for confirmation."
            if result["requires_expert_review"]
            else "✅ High confidence prediction."
        ),
    }
    return JSONResponse(content=response)


@router.get("/classes")
def list_classes():
    """Return all 23 supported disease/healthy classes."""
    from vision_engine import DISEASE_CLASSES, DISPLAY_NAMES
    return [
        {"class_key": c, "display_name": DISPLAY_NAMES.get(c, c)}
        for c in DISEASE_CLASSES
    ]


@router.get("/health")
def vision_health():
    """Check if the vision model is loaded and ready."""
    return {
        "status": "ready" if vision_model._loaded else "not_loaded",
        "model": "EfficientNetV2-S",
        "num_classes": 23,
    }
