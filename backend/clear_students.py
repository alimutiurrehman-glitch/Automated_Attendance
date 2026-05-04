"""
One-time script to delete all documents from the 'students' collection
and clear the 'studentIds' array from all class documents.
"""
import firebase_admin
from firebase_admin import credentials, firestore
import os

cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), "firebase-credentials.json"))
firebase_admin.initialize_app(cred)
db = firestore.client()

# 1. Delete all student documents
print("Deleting all student documents...")
students = db.collection('students').stream()
deleted = 0
for doc in students:
    doc.reference.delete()
    deleted += 1
print(f"  ✓ Deleted {deleted} students.")

# 2. Clear studentIds from all class documents
print("Clearing studentIds from all classes...")
classes = db.collection('classes').stream()
cleared = 0
for doc in classes:
    doc.reference.update({'studentIds': []})
    cleared += 1
print(f"  ✓ Cleared studentIds from {cleared} classes.")

print("\nDone! All student data has been removed.")
