"""
One-time script to create a Firebase Auth user + Firestore profile.
"""
import firebase_admin
from firebase_admin import credentials, firestore, auth
import os

cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), "firebase-credentials.json"))
firebase_admin.initialize_app(cred)
db = firestore.client()

NAME     = "Dr Usama"
EMAIL    = "instructor@test.com"
PASSWORD = "123456"
ROLE     = "instructor"

# Create Firebase Auth user
user = auth.create_user(email=EMAIL, password=PASSWORD, display_name=NAME)
print(f"✓ Auth user created: {user.uid}")

# Create Firestore profile
db.collection('users').document(user.uid).set({
    "name": NAME,
    "email": EMAIL,
    "role": ROLE,
})
print(f"✓ Firestore profile created with role '{ROLE}'")
print(f"\nAccount ready → {EMAIL} / {PASSWORD}")
