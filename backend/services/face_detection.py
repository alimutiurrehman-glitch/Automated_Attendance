"""
Face detection service using InsightFace's built-in RetinaFace detector.
Handles multi-face detection from classroom group photos.
"""

import numpy as np
import cv2
import insightface
from insightface.app import FaceAnalysis
from config import INSIGHTFACE_MODEL, MIN_FACE_SIZE

# Global model instance (loaded once)
_face_app = None


def get_face_app() -> FaceAnalysis:
    """Get or initialize the InsightFace analysis app (singleton)."""
    global _face_app
    if _face_app is None:
        _face_app = FaceAnalysis(
            name=INSIGHTFACE_MODEL,
            providers=["CPUExecutionProvider"],
        )
        _face_app.prepare(ctx_id=-1, det_size=(640, 640))
    return _face_app


def detect_faces(image: np.ndarray) -> list:
    """
    Detect all faces in an image using InsightFace.
    
    Args:
        image: BGR image as numpy array (preprocessed)
        
    Returns:
        List of detected face objects, each containing:
        - bbox: bounding box [x1, y1, x2, y2]
        - embedding: 512-d face embedding vector
        - det_score: detection confidence score
        - landmark: facial landmarks
    """
    app = get_face_app()
    
    # Run detection + recognition
    faces = app.get(image)
    
    # Filter by minimum face size
    valid_faces = []
    for face in faces:
        bbox = face.bbox
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        if w >= MIN_FACE_SIZE and h >= MIN_FACE_SIZE:
            valid_faces.append(face)
    
    return valid_faces


def extract_face_crops(image: np.ndarray, faces: list, padding: int = 20) -> list:
    """
    Extract cropped face images from detected face bounding boxes.
    
    Args:
        image: Original BGR image
        faces: List of detected face objects
        padding: Extra pixels around face crop
        
    Returns:
        List of cropped face images as numpy arrays
    """
    h, w = image.shape[:2]
    crops = []
    
    for face in faces:
        bbox = face.bbox.astype(int)
        x1 = max(0, bbox[0] - padding)
        y1 = max(0, bbox[1] - padding)
        x2 = min(w, bbox[2] + padding)
        y2 = min(h, bbox[3] + padding)
        
        crop = image[y1:y2, x1:x2]
        crops.append(crop)
    
    return crops


def get_face_embedding(image: np.ndarray) -> np.ndarray | None:
    """
    Extract face embedding from an image containing a single face.
    Used for enrollment.
    
    Args:
        image: BGR image containing exactly one face
        
    Returns:
        512-d embedding vector or None if no face detected
    """
    app = get_face_app()
    faces = app.get(image)
    
    if len(faces) == 0:
        return None
    
    if len(faces) > 1:
        # Pick the largest face
        areas = [(f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]) for f in faces]
        faces = [faces[np.argmax(areas)]]
    
    return faces[0].embedding
