import firebase_admin
from firebase_admin import credentials, firestore
import os

cred = credentials.Certificate("firebase-credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

try:
    db.collection('test').document('test').set({
        'nested': [[1.0, 2.0]]
    })
    print("SUCCESS")
except Exception as e:
    print("ERROR:", e)
