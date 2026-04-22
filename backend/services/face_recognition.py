"""
Face recognition and matching service.
Compares detected face embeddings against enrolled student embeddings
using cosine similarity.
"""

import numpy as np
from config import RECOGNITION_THRESHOLD, LOW_CONFIDENCE_THRESHOLD


def cosine_similarity(embedding1: np.ndarray, embedding2: np.ndarray) -> float:
    """Compute cosine similarity between two embedding vectors."""
    dot = np.dot(embedding1, embedding2)
    norm1 = np.linalg.norm(embedding1)
    norm2 = np.linalg.norm(embedding2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return float(dot / (norm1 * norm2))


def normalize_similarity(similarity: float) -> float:
    """
    Normalize cosine similarity from [-1, 1] range to [0, 1] confidence score.
    InsightFace embeddings are already normalized, so similarity is typically in [0, 1].
    """
    return max(0.0, min(1.0, (similarity + 1.0) / 2.0))
