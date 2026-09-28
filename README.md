# AgriShield: Comprehensive Agricultural Risk Management System

AgriShield is an end-to-end platform designed to empower farmers and agricultural officials with real-time pest prediction, crop health diagnostics, weather integration, and actionable insights. The system consists of a mobile application for farmers, an administrative dashboard for officials, and a powerful suite of machine learning models.

## 🚀 System Architecture

The project is divided into several key components:

### 1. AgriShield (Mobile App)
- **Tech Stack**: Flutter / Dart
- **Location**: `AgriShield/`
- **Features**: 
  - Crop health scanning and diagnostics.
  - Real-time weather and pest outbreak alerts.
  - Localized advisory for Integrated Pest Management (IPM).

### 2. Farmer Backend (crop-risk-system)
- **Tech Stack**: Python (FastAPI), SQLAlchemy, ONNX, XGBoost
- **Location**: `crop-risk-system/`
- **Features**:
  - Exposes REST APIs for the mobile app.
  - Serves predictions from the ML models.
  - Manages pest thresholds, disease databases, and epidemiology data.

### 3. Agricultural Officials Dashboard
- **Tech Stack**: React (Frontend) + FastAPI (Backend)
- **Location**: `Agricultural Officials Dashboard/`
- **Features**:
  - Regional overview of crop health and pest hotspots.
  - Tools for broadcasting alerts to farmers.
  - Data ingestion management from sensors and pest traps.

### 4. Machine Learning & Vision Models
- **Tech Stack**: Python, Scikit-learn, ONNX, PyTorch/TensorFlow (for training)
- **Locations**: `Model A (dataset)/`, `Model B/`, `Model B Vision/`
- **Features**:
  - Pest infestation likelihood prediction.
  - Vision-based crop disease classification.
  - Active learning loop for continuous model improvement (`Active Learning Loop/`).

## 🛠 Prerequisites

To run the entire system locally, you'll need:
- **Python 3.9+**
- **Node.js 18+** (for the Admin frontend)
- **Flutter SDK** (for the Mobile App)
- **Docker** (optional, but recommended for consistent environments)

## 🏃 Getting Started

### Quick Start (Windows)
We provide a convenient batch script to spin up the local environment (FastAPI backends and React frontend):

```bash
# From the project root, simply run:
start_all.bat
```
This will launch:
- Farmer Backend on `http://localhost:8000`
- Admin Backend on `http://localhost:8002`
- Admin Frontend on `http://localhost:3000`

### Manual Setup & Execution

#### 1. Farmer Backend
```bash
cd crop-risk-system
pip install -r ../requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 2. Admin Backend
```bash
cd "Agricultural Officials Dashboard"
pip install -r requirements.txt  # If available, otherwise use root requirements
uvicorn main:app --reload --host 0.0.0.0 --port 8002
```

#### 3. Admin Frontend
```bash
cd "Agricultural Officials Dashboard\frontend"
npm install
npm run dev
```

#### 4. AgriShield Mobile App
Ensure an Android/iOS emulator is running or a physical device is connected.
```bash
cd AgriShield
flutter pub get
flutter run
```

## 📚 Documentation
For a more detailed breakdown of APIs, database schemas, and ML architectures, refer to the documentation in the `/docs/` directory.

## 🤝 Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
