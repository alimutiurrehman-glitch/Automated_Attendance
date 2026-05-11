"""
Matching engine: matches detected face embeddings against enrolled student embeddings.
Handles:
- One-to-one matching (each detected face maps to at most one student)
- Duplicate prevention (each student can only be matched once)
- Confidence thresholding with low-confidence flagging
"""

import numpy as np
import cv2
import base64
from typing import Any
from services.face_recognition import cosine_similarity, normalize_similarity
from config import RECOGNITION_THRESHOLD, LOW_CONFIDENCE_THRESHOLD


def match_faces(
    detected_faces: list,
    enrolled_students: list[dict],
    cv_image: np.ndarray = None,
) -> dict:
    """
    Match detected faces against enrolled students.
    
    Args:
        detected_faces: List of InsightFace face objects with .embedding attribute
        enrolled_students: List of dicts with keys:
            - student_id: str
            - full_name: str
            - embeddings: list of list of floats (multiple enrollment embeddings)
    
    Returns:
        Dictionary with:
        - recognized: list of {student_id, full_name, confidence, face_index}
        - unresolved: list of {faceIndex, bestMatchConfidence, bestMatchStudentId, faceImageUrl, embedding}
        - detected_faces_count: int
    """
    if not detected_faces or not enrolled_students:
        return {
            "recognized": [],
            "unresolved": [
                {
                    "faceIndex": i, 
                    "bestMatchConfidence": None, 
                    "bestMatchStudentId": None,
                    "faceImageUrl": None,
                    "embedding": detected_faces[i].embedding.tolist() if detected_faces and hasattr(detected_faces[i], 'embedding') else None
                }
                for i in range(len(detected_faces))
            ],
            "detected_faces_count": len(detected_faces),
        }
    
    # Build enrolled embeddings matrix
    enrolled_data = []
    for student in enrolled_students:
        for emb in student["embeddings"]:
            enrolled_data.append({
                "student_id": student["student_id"],
                "full_name": student.get("full_name", ""),
                "embedding": np.array(emb, dtype=np.float32),
            })
    
    # Track which students have been matched (prevent duplicates)
    matched_student_ids: set[str] = set()
    recognized = []
    unresolved = []
    
    # For each detected face, find best matching enrolled student
    for face_idx, face in enumerate(detected_faces):
        detected_embedding = face.embedding
        
        best_similarity = -1.0
        best_student_id = None
        best_student_name = None
        
        for enrolled in enrolled_data:
            if enrolled["student_id"] in matched_student_ids:
                continue  # Skip already-matched students
            
            sim = cosine_similarity(detected_embedding, enrolled["embedding"])
            
            if sim > best_similarity:
                best_similarity = sim
                best_student_id = enrolled["student_id"]
                best_student_name = enrolled["full_name"]
        
        confidence = normalize_similarity(best_similarity)
        
        if best_similarity >= RECOGNITION_THRESHOLD and best_student_id is not None:
            # Confident match
            recognized.append({
                "studentId": best_student_id,
                "fullName": best_student_name,
                "confidence": round(confidence, 4),
                "faceIndex": face_idx,
            })
            matched_student_ids.add(best_student_id)
        
        elif best_similarity >= LOW_CONFIDENCE_THRESHOLD and best_student_id is not None:
            # Low-confidence: flag for manual review
            unresolved_item = {
                "faceIndex": face_idx,
                "bestMatchConfidence": round(confidence, 4),
                "bestMatchStudentId": best_student_id,
                "embedding": detected_embedding.tolist()
            }
            if cv_image is not None and hasattr(face, 'bbox'):
                bbox = face.bbox.astype(int)
                x1, y1, x2, y2 = max(0, bbox[0]), max(0, bbox[1]), min(cv_image.shape[1], bbox[2]), min(cv_image.shape[0], bbox[3])
                face_crop = cv_image[y1:y2, x1:x2]
                if face_crop.size > 0:
                    _, buffer = cv2.imencode('.jpg', face_crop)
                    unresolved_item["faceImageUrl"] = f"data:image/jpeg;base64,{base64.b64encode(buffer).decode('utf-8')}"
            unresolved.append(unresolved_item)
        
        else:
            # No match at all
            unresolved_item = {
                "faceIndex": face_idx,
                "bestMatchConfidence": round(confidence, 4) if best_student_id else None,
                "bestMatchStudentId": best_student_id,
                "embedding": detected_embedding.tolist()
            }
            if cv_image is not None and hasattr(face, 'bbox'):
                bbox = face.bbox.astype(int)
                x1, y1, x2, y2 = max(0, bbox[0]), max(0, bbox[1]), min(cv_image.shape[1], bbox[2]), min(cv_image.shape[0], bbox[3])
                face_crop = cv_image[y1:y2, x1:x2]
                if face_crop.size > 0:
                    _, buffer = cv2.imencode('.jpg', face_crop)
                    unresolved_item["faceImageUrl"] = f"data:image/jpeg;base64,{base64.b64encode(buffer).decode('utf-8')}"
            unresolved.append(unresolved_item)
    
    return {
        "recognized": recognized,
        "unresolved": unresolved,
        "detected_faces_count": len(detected_faces),
    }
