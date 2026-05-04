"""
Configuration for the Automated Attendance Backend Service.
All thresholds and settings are configurable here.
"""

# Recognition confidence threshold (0.0 to 1.0)
# Faces below this threshold are marked as "unresolved" for manual review
# 0.40 maps to ~70% confidence in the app
RECOGNITION_THRESHOLD = 0.40

# Low-confidence zone: between this and RECOGNITION_THRESHOLD,
# matches are flagged for instructor review
# 0.30 maps to ~65% confidence
LOW_CONFIDENCE_THRESHOLD = 0.30

# Maximum image dimension for processing (for performance)
MAX_IMAGE_DIMENSION = 2560

# Face detection minimum size (pixels)
MIN_FACE_SIZE = 20

# InsightFace model name
INSIGHTFACE_MODEL = "buffalo_l"

import os

# Firebase credentials — supports two modes:
# 1. FIREBASE_CREDENTIALS_JSON env var: full JSON string (used on Railway / cloud)
# 2. Local file path fallback (used in local development)
FIREBASE_CREDENTIALS_JSON_ENV = os.environ.get("FIREBASE_CREDENTIALS_JSON")
FIREBASE_CREDENTIALS_PATH = os.path.join(os.path.dirname(__file__), "firebase-credentials.json")

# Server settings
HOST = "0.0.0.0"
PORT = 8000
