import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add the main project root to path so we can import app.models correctly
sys.path.insert(0, r"D:\PDD2\crop-risk-system")

import app.models as models

# Override the database URL to point to the ABSOLUTE path of the farmer site's database
# This prevents the Admin dashboard from creating a blank database in its own folder.
SQLALCHEMY_DATABASE_URL = "sqlite:///D:/PDD2/crop-risk-system/crop_risk.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)
