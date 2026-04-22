"""
Automated Classroom Attendance Marker — Backend Service
FastAPI server for face detection and recognition.
"""

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from routes.attendance import router as attendance_router
from routes.enrollment import router as enrollment_router
from config import HOST, PORT

app = FastAPI(
    title="Attendance Marker API",
    description="Backend service for automated classroom attendance using face recognition",
    version="1.0.0",
)

# CORS middleware — allow Flutter app requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(attendance_router)
app.include_router(enrollment_router)

# Serve static frontend files (CSS, JS)
FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "frontend")
app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "service": "Attendance Marker API"}


@app.get("/api")
async def api_info():
    """API info endpoint — returns JSON metadata."""
    return {
        "name": "Attendance Marker API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }


@app.get("/")
async def root():
    """Serve the web dashboard."""
    return FileResponse(os.path.join(FRONTEND_DIR, "index.html"))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
