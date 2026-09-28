@echo off
echo Starting Farmer Backend (Port 8000)...
start "Farmer Backend" cmd /c "cd /d %~dp0crop-risk-system && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo Starting Admin Backend (Port 8002)...
start "Admin Backend" cmd /c "cd /d %~dp0Agricultural Officials Dashboard && uvicorn main:app --reload --host 0.0.0.0 --port 8002"

echo Starting Admin Frontend (Port 3000)...
start "Admin Frontend" cmd /c "cd /d %~dp0Agricultural Officials Dashboard\frontend && npm run dev"

echo All services started in separate windows!
