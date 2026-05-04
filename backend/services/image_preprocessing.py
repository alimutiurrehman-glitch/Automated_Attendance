"""
Image preprocessing pipeline for improving face detection under varied lighting.
Uses OpenCV for contrast enhancement, denoising, normalization, and exposure correction.
"""

import cv2
import numpy as np
from PIL import Image


def preprocess_image(image: np.ndarray) -> np.ndarray:
    """
    Apply full preprocessing pipeline to improve face detection accuracy.
    
    Steps:
    1. Resize if too large
    2. Denoise
    3. Auto contrast/brightness correction
    4. CLAHE (adaptive histogram equalization)
    
    Args:
        image: BGR image as numpy array
        
    Returns:
        Preprocessed BGR image
    """
    from config import MAX_IMAGE_DIMENSION
    
    # Step 1: Resize if too large (maintains aspect ratio)
    image = resize_if_needed(image, MAX_IMAGE_DIMENSION)
    
    # Step 2: Denoise
    image = denoise(image)
    
    # Step 3: Auto brightness/contrast correction
    image = auto_brightness_contrast(image)
    
    # Step 4: CLAHE on luminance channel
    image = apply_clahe(image)
    
    return image


def resize_if_needed(image: np.ndarray, max_dim: int) -> np.ndarray:
    """Resize image if any dimension exceeds max_dim, preserving aspect ratio."""
    h, w = image.shape[:2]
    if max(h, w) <= max_dim:
        return image
    
    scale = max_dim / max(h, w)
    new_w = int(w * scale)
    new_h = int(h * scale)
    return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)


def denoise(image: np.ndarray) -> np.ndarray:
    """Apply fast non-local means denoising."""
    return cv2.fastNlMeansDenoisingColored(image, None, 6, 6, 7, 21)


def auto_brightness_contrast(image: np.ndarray, clip_pct: float = 1.0) -> np.ndarray:
    """
    Automatically adjusts brightness and contrast using histogram clipping.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Calculate histogram
    hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
    total_pixels = gray.shape[0] * gray.shape[1]
    clip_count = total_pixels * clip_pct / 100.0
    
    # Find min and max intensity after clipping
    cumsum = np.cumsum(hist.flatten())
    min_gray = 0
    max_gray = 255
    
    for i in range(256):
        if cumsum[i] > clip_count:
            min_gray = i
            break
    
    for i in range(255, -1, -1):
        if cumsum[i] < (total_pixels - clip_count):
            max_gray = i
            break
    
    if max_gray <= min_gray:
        return image
    
    # Apply linear stretch
    alpha = 255.0 / (max_gray - min_gray)
    beta = -min_gray * alpha
    
    result = cv2.convertScaleAbs(image, alpha=alpha, beta=beta)
    return result


def apply_clahe(image: np.ndarray) -> np.ndarray:
    """
    Apply CLAHE (Contrast Limited Adaptive Histogram Equalization) 
    to the luminance channel for better face visibility in varied lighting.
    """
    # Convert to LAB color space
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l_channel, a_channel, b_channel = cv2.split(lab)
    
    # Apply CLAHE to luminance channel
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l_enhanced = clahe.apply(l_channel)
    
    # Merge back
    lab_enhanced = cv2.merge([l_enhanced, a_channel, b_channel])
    result = cv2.cvtColor(lab_enhanced, cv2.COLOR_LAB2BGR)
    
    return result


def assess_image_quality(image: np.ndarray) -> dict:
    """
    Assess the quality of an image for face detection suitability.
    
    Returns:
        Dictionary with quality metrics and overall assessment.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Brightness assessment
    mean_brightness = np.mean(gray)
    brightness_ok = 40 < mean_brightness < 220
    
    # Contrast assessment
    contrast = np.std(gray)
    contrast_ok = contrast > 30
    
    # Blur assessment (Laplacian variance)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    blur_ok = laplacian_var > 50
    
    # Overall quality
    quality_score = 0
    if brightness_ok:
        quality_score += 1
    if contrast_ok:
        quality_score += 1
    if blur_ok:
        quality_score += 1
    
    quality_map = {0: "poor", 1: "low", 2: "acceptable", 3: "good"}
    
    return {
        "brightness": float(mean_brightness),
        "brightness_ok": bool(brightness_ok),
        "contrast": float(contrast),
        "contrast_ok": bool(contrast_ok),
        "blur_score": float(laplacian_var),
        "blur_ok": bool(blur_ok),
        "overall_quality": quality_map[quality_score],
        "quality_score": int(quality_score),
        "warnings": _generate_warnings(bool(brightness_ok), bool(contrast_ok), bool(blur_ok), float(mean_brightness)),
    }


def _generate_warnings(brightness_ok, contrast_ok, blur_ok, mean_brightness):
    """Generate human-readable warnings for image quality issues."""
    warnings = []
    if not brightness_ok:
        if mean_brightness < 40:
            warnings.append("Image is too dark. Try improving classroom lighting.")
        else:
            warnings.append("Image is overexposed. Reduce direct light on the camera.")
    if not contrast_ok:
        warnings.append("Image has low contrast. Ensure varied lighting on faces.")
    if not blur_ok:
        warnings.append("Image is blurry. Hold the camera steady and ensure focus.")
    return warnings
