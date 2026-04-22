"""
Enrollment API routes.
Handles face embedding generation for student enrollment.
"""

import io
import cv2
import numpy as np
from fastapi import APIRouter, UploadFile, File, HTTPException
from PIL import Image

from services.face_detection import get_face_embedding
from services.image_preprocessing import preprocess_image, assess_image_quality

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
