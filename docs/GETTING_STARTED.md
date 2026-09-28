# AgriShield Getting Started Guide

Welcome to AgriShield! This guide will walk you through the steps to set up the system locally, explore its features, and understand how the different components interact.

## 1. System Overview

AgriShield consists of four main pillars:
1. **AgriShield Mobile App**: The primary interface for farmers to scan crops, view risk predictions, and receive alerts.
2. **crop-risk-system (Farmer Backend)**: The core engine that processes requests, interacts with Machine Learning models, and fetches weather data.
3. **Agricultural Officials Dashboard**: A web-based portal for administrators to monitor regional data and manage the system.
4. **Machine Learning Models**: The intelligence layer that provides disease classification (Vision) and pest infestation risk forecasting.

## 2. Environment Setup

### 2.1 Dependencies
Ensure you have the following installed on your machine:
- **Python 3.9+** (For FastApi backends and ML scripts)
- **Node.js & npm** (For the Admin Dashboard Frontend)
- **Flutter SDK** (For compiling the Mobile App)
- **Git** (For version control)

### 2.2 Running the Services

We have provided a convenient batch script to spin up the local web services.
From the root of the project, run:

```bash
start_all.bat
```

This script starts:
- The **Farmer Backend** at `http://localhost:8000` (FastAPI)
- The **Admin Backend** at `http://localhost:8002` (FastAPI)
- The **Admin Dashboard** at `http://localhost:3000` (React)

## 3. Trying Out the App

### 3.1 The Mobile App (AgriShield)
To run the mobile application, navigate to the `AgriShield/` directory.

1. Fetch the Flutter dependencies:
   ```bash
   flutter pub get
   ```
2. Start the app on a connected device or emulator:
   ```bash
   flutter run
   ```

**Features to Explore**:
- Navigate to the **Crop Scanner** to simulate disease detection using the Vision Model.
- Check the **Weather & Alerts** section for real-time risk predictions based on the `crop-risk-system` backend.

### 3.2 The Admin Dashboard
Open your browser and navigate to `http://localhost:3000`.

**Features to Explore**:
- View the regional hotspot maps.
- Explore sensor data from pest traps.
- Test the alert broadcasting functionality (Note: Requires proper backend configuration).

## 4. API Documentation

Both the Farmer Backend and Admin Backend use FastAPI, meaning they come with automatic Swagger UI documentation.

Once the services are running, you can explore and test the APIs at:
- **Farmer Backend API Docs**: `http://localhost:8000/docs`
- **Admin Backend API Docs**: `http://localhost:8002/docs`

## 5. Next Steps

- **Model Retraining**: Check out the `Active Learning Loop/` directory to see how the system continuously improves its ML models based on expert feedback.
- **Custom Integrations**: Look into `crop-risk-system/app/integration_routes.py` to see how you can connect external weather or sensor APIs.

For further questions, please consult the inline code documentation or open an issue in the repository.
