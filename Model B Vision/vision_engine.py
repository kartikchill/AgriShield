"""
Vision Engine for Plant Disease Detection (Model B)
Architecture: EfficientNetV2-S with custom 3-layer classifier head
Trained on: 23 plant disease classes (PlantVillage dataset subset)
Accuracy: ~99.7% on validation set
"""
import io
import logging
from pathlib import Path

import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as T
from PIL import Image

logger = logging.getLogger(__name__)

# ─── Class Labels (embedded from checkpoint, in order) ───────────────────────
DISEASE_CLASSES = [
    "Apple___Apple_scab",
    "Apple___Black_rot",
    "Apple___Cedar_apple_rust",
    "Apple___healthy",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
    "Corn_(maize)___Common_rust_",
    "Corn_(maize)___Northern_Leaf_Blight",
    "Corn_(maize)___healthy",
    "Pepper__bell___Bacterial_spot",
    "Pepper__bell___healthy",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Tomato_Bacterial_spot",
    "Tomato_Early_blight",
    "Tomato_Late_blight",
    "Tomato_Leaf_Mold",
    "Tomato_Septoria_leaf_spot",
    "Tomato_Spider_mites_Two_spotted_spider_mite",
    "Tomato__Target_Spot",
    "Tomato__Tomato_YellowLeaf__Curl_Virus",
    "Tomato__Tomato_mosaic_virus",
    "Tomato_healthy",
]

# Human-readable names for the frontend
DISPLAY_NAMES = {
    "Apple___Apple_scab": "Apple - Apple Scab",
    "Apple___Black_rot": "Apple - Black Rot",
    "Apple___Cedar_apple_rust": "Apple - Cedar Apple Rust",
    "Apple___healthy": "Apple - Healthy",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": "Corn - Grey Leaf Spot",
    "Corn_(maize)___Common_rust_": "Corn - Common Rust",
    "Corn_(maize)___Northern_Leaf_Blight": "Corn - Northern Leaf Blight",
    "Corn_(maize)___healthy": "Corn - Healthy",
    "Pepper__bell___Bacterial_spot": "Bell Pepper - Bacterial Spot",
    "Pepper__bell___healthy": "Bell Pepper - Healthy",
    "Potato___Early_blight": "Potato - Early Blight",
    "Potato___Late_blight": "Potato - Late Blight",
    "Potato___healthy": "Potato - Healthy",
    "Tomato_Bacterial_spot": "Tomato - Bacterial Spot",
    "Tomato_Early_blight": "Tomato - Early Blight",
    "Tomato_Late_blight": "Tomato - Late Blight",
    "Tomato_Leaf_Mold": "Tomato - Leaf Mold",
    "Tomato_Septoria_leaf_spot": "Tomato - Septoria Leaf Spot",
    "Tomato_Spider_mites_Two_spotted_spider_mite": "Tomato - Spider Mites",
    "Tomato__Target_Spot": "Tomato - Target Spot",
    "Tomato__Tomato_YellowLeaf__Curl_Virus": "Tomato - Yellow Leaf Curl Virus",
    "Tomato__Tomato_mosaic_virus": "Tomato - Mosaic Virus",
    "Tomato_healthy": "Tomato - Healthy",
}

# IPM lookup key (maps predicted class to ETL system crop+pest key)
IPM_LOOKUP = {
    "Tomato_Late_blight":            {"crop": "Tomato", "pest": "Late Blight"},
    "Tomato_Early_blight":           {"crop": "Tomato", "pest": "Early Blight"},
    "Tomato_Bacterial_spot":         {"crop": "Tomato", "pest": "Bacterial Spot"},
    "Potato___Late_blight":          {"crop": "Potato", "pest": "Late Blight"},
    "Potato___Early_blight":         {"crop": "Potato", "pest": "Early Blight"},
    "Corn_(maize)___Common_rust_":   {"crop": "Corn",   "pest": "Common Rust"},
    "Corn_(maize)___Northern_Leaf_Blight": {"crop": "Corn", "pest": "Northern Leaf Blight"},
}

# ─── Transforms (ImageNet stats) ─────────────────────────────────────────────
_TRANSFORMS = T.Compose([
    T.Resize(256),
    T.CenterCrop(224),
    T.ToTensor(),
    T.Normalize(mean=[0.485, 0.456, 0.406],
                 std=[0.229, 0.224, 0.225]),
])

ALLOWED_FORMATS = {"JPEG", "JPG", "PNG", "WEBP"}
EXPERT_REVIEW_THRESHOLD = 0.70
_BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = _BASE_DIR / "Model B" / "best_plant_disease_model.pth"


def _build_model(num_classes: int = 23) -> nn.Module:
    """Reconstruct the exact EfficientNetV2-S + custom head used during training."""
    model = models.efficientnet_v2_s(weights=None)
    in_features = model.classifier[1].in_features  # 1280
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.2, inplace=True),
        nn.Linear(in_features, 512),
        nn.BatchNorm1d(512),
        nn.SiLU(),
        nn.Dropout(p=0.2),
        nn.Linear(512, num_classes),
    )
    return model


class DiseaseVisionModel:
    """
    Singleton wrapper that loads the EfficientNetV2-S checkpoint once on startup
    and exposes a thread-safe predict() method for FastAPI.
    """

    def __init__(self):
        self._model: nn.Module | None = None
        self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self._loaded = False

    def load(self):
        """Load weights from disk — call this once during app startup."""
        if self._loaded:
            return
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Model weights not found at: {MODEL_PATH}\n"
                "Place best_plant_disease_model.pth in D:\\PDD2\\Model B\\"
            )
        logger.info(f"Loading Model B from {MODEL_PATH} on {self._device}…")
        checkpoint = torch.load(MODEL_PATH, map_location=self._device, weights_only=False)
        model = _build_model(num_classes=len(DISEASE_CLASSES))
        model.load_state_dict(checkpoint["model_state_dict"], strict=True)
        model.to(self._device)
        model.eval()
        self._model = model
        self._loaded = True
        logger.info("Model B loaded successfully (EfficientNetV2-S, 23 classes, ~99.7% acc)")

    def predict(self, image_bytes: bytes) -> dict:
        """
        Run inference on raw image bytes.

        Returns:
            {
                "disease_class": str,          # internal class key
                "display_name":  str,          # human-readable label
                "confidence":    float,        # 0-1
                "is_healthy":    bool,
                "requires_expert_review": bool,# True if confidence < 0.70
                "ipm_lookup":    dict | None,  # crop+pest keys for ETL system
                "top3":          list[dict],   # top-3 predictions
            }
        """
        if not self._loaded:
            raise RuntimeError("Model not loaded. Call DiseaseVisionModel.load() first.")

        # ── Open & validate image ──────────────────────────────────────────
        try:
            img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        except Exception as exc:
            raise ValueError(f"Cannot decode image: {exc}") from exc

        if img.format and img.format.upper() not in ALLOWED_FORMATS:
            raise ValueError(
                f"Unsupported image format: {img.format}. "
                f"Accepted: {', '.join(ALLOWED_FORMATS)}"
            )

        # ── Preprocess ────────────────────────────────────────────────────
        try:
            tensor = _TRANSFORMS(img).unsqueeze(0).to(self._device)  # [1,3,224,224]
        except Exception as exc:
            raise ValueError(f"Image preprocessing failed: {exc}") from exc

        # ── Inference ─────────────────────────────────────────────────────
        try:
            with torch.no_grad():
                logits = self._model(tensor)           # [1, 23]
                probs  = torch.softmax(logits, dim=1)  # [1, 23]
        except Exception as exc:
            raise RuntimeError(f"Inference failed (tensor/dimension error): {exc}") from exc

        probs_cpu = probs[0].cpu().tolist()

        # ── Parse results ─────────────────────────────────────────────────
        top_idx        = int(probs[0].argmax())
        top_class      = DISEASE_CLASSES[top_idx]
        top_conf       = probs_cpu[top_idx]

        # Top-3
        sorted_indices = sorted(range(len(probs_cpu)), key=lambda i: probs_cpu[i], reverse=True)
        top3 = [
            {
                "rank":        rank + 1,
                "disease_class": DISEASE_CLASSES[i],
                "display_name":  DISPLAY_NAMES.get(DISEASE_CLASSES[i], DISEASE_CLASSES[i]),
                "confidence":  round(probs_cpu[i], 4),
            }
            for rank, i in enumerate(sorted_indices[:3])
        ]

        return {
            "disease_class":         top_class,
            "display_name":          DISPLAY_NAMES.get(top_class, top_class),
            "confidence":            round(top_conf, 4),
            "is_healthy":            "healthy" in top_class.lower(),
            "requires_expert_review": top_conf < EXPERT_REVIEW_THRESHOLD,
            "ipm_lookup":            IPM_LOOKUP.get(top_class),
            "top3":                  top3,
        }


# Global singleton — imported by routes.py and registered in main.py lifespan
vision_model = DiseaseVisionModel()
