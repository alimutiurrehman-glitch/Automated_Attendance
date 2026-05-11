"""
Enrollment API routes.
Handles face embedding generation for student enrollment.
"""

import io
import cv2
import numpy as np
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from PIL import Image

from services.face_detection import get_face_embedding
from services.image_preprocessing import preprocess_image, assess_image_quality
from services.firebase_service import get_all_classes, register_student_in_db, get_students_in_class, update_student_embedding

router = APIRouter(prefix="/api/enrollment", tags=["Enrollment"])


@router.post("/generate-embedding")
async def generate_embedding(
    image: UploadFile = File(...),
):
    """
    Generate a face embedding from a single face image.
    Used during student enrollment.
    
    Receives:
    - image: A clear frontal face image of one student
    
    Returns:
    - embedding: 512-d face embedding vector
    - quality: Image quality assessment
    """
    try:
        # Read image
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents)).convert("RGB")
        cv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Assess quality
        quality = assess_image_quality(cv_image)
        
        if quality["quality_score"] < 2:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Image quality is too low for enrollment.",
                    "quality": quality,
                    "warnings": quality["warnings"],
                },
            )
        
        # Preprocess
        processed = preprocess_image(cv_image)
        
        # Extract embedding
        embedding = get_face_embedding(processed)
        
        if embedding is None:
            raise HTTPException(
                status_code=400,
                detail="No face detected in the image. Please upload a clear frontal face photo.",
            )
        
        return {
            "embedding": embedding.tolist(),
            "quality": quality,
            "message": "Face embedding generated successfully.",
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating embedding: {str(e)}",
        )

@router.get("/classes")
async def fetch_classes():
    """
    Fetch all available classes for self-registration.
    """
    try:
        classes = get_all_classes()
        return {"classes": classes}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching classes: {str(e)}",
        )

@router.post("/self-register")
async def self_register(
    image: UploadFile = File(...),
    name: str = Form(...),
    roll_number: str = Form(...),
    class_id: str = Form(...),
):
    """
    Generate embedding and register student in Firestore.
    """
    try:
        # Read image
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents)).convert("RGB")
        cv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Assess quality
        quality = assess_image_quality(cv_image)
        if quality["quality_score"] < 2:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Image quality is too low for enrollment.",
                    "quality": quality,
                },
            )
        
        # Preprocess
        processed = preprocess_image(cv_image)
        
        # Extract embedding
        embedding = get_face_embedding(processed)
        if embedding is None:
            raise HTTPException(
                status_code=400,
                detail="No face detected in the image. Please upload a clear frontal face photo.",
            )
        
        # Register student in Firebase
        student_id = register_student_in_db(
            name=name,
            roll_number=roll_number,
            class_id=class_id,
            face_embedding=embedding.tolist()
        )
        
        return {
            "student_id": student_id,
            "message": "Student successfully registered.",
            "quality": quality,
        }
    
    except HTTPException:
        raise
    except ValueError as e:
        # Duplicate roll number or validation error → return 400 with clear message
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error registering student: {str(e)}",
        )

@router.get("/students/{class_id}")
async def fetch_students(class_id: str):
    """
    Fetch all students for a specific class.
    """
    try:
        students = get_students_in_class(class_id)
        return {"students": students}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching students: {str(e)}",
        )

@router.post("/admin-enroll-face")
async def admin_enroll_face(
    image: UploadFile = File(...),
    student_id: str = Form(...),
):
    """
    Generate embedding from an image and append it to an existing student.
    """
    try:
        # Read image
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents)).convert("RGB")
        cv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Assess quality
        quality = assess_image_quality(cv_image)
        if quality["quality_score"] < 2:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Image quality is too low for enrollment.",
                    "quality": quality,
                },
            )
        
        # Preprocess
        processed = preprocess_image(cv_image)
        
        # Extract embedding
        embedding = get_face_embedding(processed)
        if embedding is None:
            raise HTTPException(
                status_code=400,
                detail="No face detected in the image. Please upload a clear frontal face photo.",
            )
        
        # Append embedding in Firebase
        update_student_embedding(student_id, embedding.tolist())
        
        return {
            "message": "Face successfully enrolled for the student.",
            "quality": quality,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error enrolling face: {str(e)}",
        )

