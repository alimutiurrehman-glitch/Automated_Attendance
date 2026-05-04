import json
import firebase_admin
from firebase_admin import credentials, firestore
from config import FIREBASE_CREDENTIALS_JSON_ENV, FIREBASE_CREDENTIALS_PATH
from datetime import datetime

# Initialize Firebase Admin SDK
# Priority: env var JSON string (Railway) → local credentials file (dev)
try:
    if not firebase_admin._apps:
        if FIREBASE_CREDENTIALS_JSON_ENV:
            # Cloud deployment: credentials passed as a JSON string env var
            cred_dict = json.loads(FIREBASE_CREDENTIALS_JSON_ENV)
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            print("Firebase initialized from FIREBASE_CREDENTIALS_JSON env var.")
        elif FIREBASE_CREDENTIALS_PATH:
            # Local development: use the credentials file
            cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
            print("Firebase initialized from local credentials file.")
        else:
            print("WARNING: No Firebase credentials found.")
except Exception as e:
    print(f"Error initializing Firebase Admin: {e}")

def get_db():
    """Return the Firestore database instance."""
    return firestore.client()

def get_all_classes():
    """Fetch all classes from the classes collection."""
    db = get_db()
    try:
        classes_ref = db.collection('classes')
        docs = classes_ref.stream()
        classes = []
        for doc in docs:
            data = doc.to_dict()
            classes.append({
                "id": doc.id,
                "className": data.get("className", ""),
                "section": data.get("section", ""),
                "instructorId": data.get("instructorId", "")
            })
        return classes
    except Exception as e:
        raise Exception(f"Failed to fetch classes: {e}")

def register_student_in_db(name, roll_number, class_id, face_embedding):
    """
    Registers a student in Firestore:
    1. Creates a document in the 'students' collection.
    2. Updates the 'studentIds' array in the corresponding 'class' document.
    """
    db = get_db()
    try:
        # Create student document
        student_data = {
            "name": name,
            "rollNumber": roll_number,
            "classId": class_id,
            "faceEmbeddings": [json.dumps(face_embedding)], # Stored as JSON strings to bypass Firestore nested array limitation
            "enrollmentImages": [], # Will be empty since we're using web upload for now
            "createdAt": datetime.utcnow().isoformat() + "Z"
        }
        
        # Add to students collection
        student_ref = db.collection('students').document()
        student_ref.set(student_data)
        student_id = student_ref.id
        
        # Add student ID to the class's studentIds array
        class_ref = db.collection('classes').document(class_id)
        class_ref.update({
            "studentIds": firestore.ArrayUnion([student_id])
        })
        
        return student_id
        
    except Exception as e:
        raise Exception(f"Failed to register student in DB: {e}")
