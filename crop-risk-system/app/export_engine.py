import csv
import shutil
from pathlib import Path
from sqlalchemy.orm import Session
from .models import RetrainingArchive

class RetrainingPipeline:
    def __init__(self, export_dir: str = "exports"):
        self.export_dir = Path(export_dir)
        self.export_dir.mkdir(exist_ok=True, parents=True)

    def export_weather_risk(self, db: Session) -> str:
        records = db.query(RetrainingArchive).filter(RetrainingArchive.data_type == "WEATHER_RISK").all()
        csv_path = self.export_dir / "weather_retraining.csv"
        
        with open(csv_path, mode='w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(["id", "source_file_path", "predicted_label", "true_label", "confidence_score", "added_on"])
            for r in records:
                writer.writerow([r.id, r.source_file_path, r.predicted_label, r.true_label, r.confidence_score, r.added_on])
        
        return str(csv_path.absolute())

    def export_image_vision(self, db: Session) -> str:
        records = db.query(RetrainingArchive).filter(RetrainingArchive.data_type == "IMAGE_VISION").all()
        dataset_dir = self.export_dir / "dataset" / "train"
        
        for r in records:
            true_label_dir = dataset_dir / str(r.true_label)
            true_label_dir.mkdir(exist_ok=True, parents=True)
            
            src_path = Path(r.source_file_path)
            if src_path.exists() and src_path.is_file():
                dest_path = true_label_dir / src_path.name
                shutil.copy2(src_path, dest_path)
                
        return str(dataset_dir.absolute())
