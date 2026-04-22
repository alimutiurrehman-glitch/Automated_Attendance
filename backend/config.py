"""
Configuration for the Automated Attendance Backend Service.
All thresholds and settings are configurable here.
"""

# Recognition confidence threshold (0.0 to 1.0)
# Faces below this threshold are marked as "unresolved" for manual review
RECOGNITION_THRESHOLD = 0.45

# Low-confidence zone: between this and RECOGNITION_THRESHOLD,
# matches are flagged for instructor review
LOW_CONFIDENCE_THRESHOLD = 0.35

# Maximum image dimension for processing (for performance)
MAX_IMAGE_DIMENSION = 1920

# Face detection minimum size (pixels)
MIN_FACE_SIZE = 20

# InsightFace model name
INSIGHTFACE_MODEL = "buffalo_l"

# Firebase Admin SDK service account path
# Set to None if not using Firebase Admin from backend
FIREBASE_CREDENTIALS_PATH = None

# Server settings
HOST = "0.0.0.0"
PORT = 8000
