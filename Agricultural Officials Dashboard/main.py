from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import routes_triage
import routes_analytics
import routes_insurance


app = FastAPI(
    title="Agricultural Officials Dashboard API",
    description="Backend for the KVK Admin Dashboard. Handles triage and analytics.",
    version="1.0.0"
)

# Strict CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all for local dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(routes_triage.router)
app.include_router(routes_analytics.router)
app.include_router(routes_insurance.router)


from fastapi.responses import FileResponse

@app.get("/")
def root():
    return FileResponse("index.html")


