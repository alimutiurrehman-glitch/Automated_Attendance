"""
Attendance processing API routes.
Handles classroom image processing for face detection and recognition.
"""

import json
import io
import cv2
import numpy as np
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from PIL import Image

from services.image_preprocessing import preprocess_image, assess_image_quality
from services.face_detection import detect_faces
from services.matching_engine import match_faces

router = APIRouter(prefix="/api/attendance", tags=["Attendance"])


@router.post("/process")
async def process_attendance_image(
    image: UploadFile = File(...),
    class_id: str = Form(...),
    enrolled_students: str = Form(...),
):
    """
    Process a classroom group photo for attendance.
    
    Receives:
    - image: The classroom group photo
    - class_id: ID of the class
    - enrolled_students: JSON string of enrolled students with embeddings
    
    Returns:
    - recognized: List of recognized students with confidence
    - unresolved: List of unresolved face detections
    - detected_faces_count: Total faces detected
    - image_quality: Quality assessment of the uploaded image
    """
    try:
        # Read image
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents)).convert("RGB")
        cv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Assess image quality
        quality = assess_image_quality(cv_image)
        
        # Preprocess image
        processed_image = preprocess_image(cv_image)
        
        # Detect faces
        detected = detect_faces(processed_image)
        
        if len(detected) == 0:
            return {
                "recognized": [],
                "unresolved": [],
                "detected_faces_count": 0,
                "image_quality": quality,
                "message": "No faces detected in the image. Please try again with a clearer photo.",
            }
        
        # Parse enrolled students
        try:
            students_data = json.loads(enrolled_students)
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=400,
                detail="Invalid enrolled_students JSON format",
            )
        
        # Run matching engine
        results = match_faces(detected, students_data, cv_image)
        results["image_quality"] = quality
        
        return results
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing image: {str(e)}",
        )
