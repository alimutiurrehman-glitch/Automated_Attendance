# Automated Classroom Attendance Marker - Setup Guide

This guide provides step-by-step instructions to set up the **Automated Classroom Attendance Marker** project, which consists of a Python FastAPI backend for face recognition and a Flutter Android application for the user interface.

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your system:

1. **[Python 3.9+](https://www.python.org/downloads/)**
2. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (version ^3.9.2)
3. **[Android Studio](https://developer.android.com/studio)** or Xcode (for running an emulator)
4. A **[Firebase](https://console.firebase.google.com/)** account and project

---

## ☁️ Firebase Configuration

Both the frontend and backend require Firebase to function. 

### Setting up the Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Enable the following services in your Firebase project:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Firebase Storage**

### Generating Backend Credentials
1. In the Firebase console, go to **Project Settings** > **Service Accounts**.
2. Click **Generate new private key** and download the `.json` file.
3. Save this file securely on your machine (e.g., `firebase-service-account.json`).

---

## ⚙️ Backend Setup (Python FastAPI)

The backend handles face detection, recognition using InsightFace, and communicates with Firebase.

### 1. Navigate to the backend directory
```bash
cd backend
```

### 2. Create and activate a Virtual Environment
It's highly recommended to use a virtual environment to manage dependencies.

**macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure the Environment
Open `backend/config.py` in your code editor and update the `FIREBASE_CREDENTIALS_PATH`:

```python
# Change this to the absolute path where you saved your Firebase private key
FIREBASE_CREDENTIALS_PATH = "/path/to/your/firebase-service-account.json"
```

*Note: You can also adjust face recognition thresholds in this file if needed.*

### 5. Run the Server
Start the FastAPI server using Uvicorn:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
> [!TIP]
> Once running, you can access the interactive API documentation at: `http://localhost:8000/docs`

---

## 📱 Frontend Setup (Flutter)

The frontend is an Android application built with Flutter, allowing instructors to capture images and review attendance.

### 1. Navigate to the frontend directory
```bash
cd attendance_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase for Flutter
To link your Flutter app to Firebase, it is recommended to use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).

1. Install the Firebase CLI if you haven't already: `npm install -g firebase-tools`
2. Log in to Firebase: `firebase login`
3. Activate the FlutterFire CLI: `dart pub global activate flutterfire_cli`
4. Run the configuration command in the `attendance_app` directory:
   ```bash
   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
   ```
This will automatically generate the `lib/firebase_options.dart` file and configure the native Android/iOS files.

### 4. Connect Frontend to your Backend
Make sure the frontend is configured to send HTTP requests to your local backend. 
- If running on an **Android Emulator**, the localhost IP is typically `http://10.0.2.2:8000`.
- If running on a **Physical Device**, ensure both your device and computer are on the same Wi-Fi network and use your computer's local IP address (e.g., `http://192.168.1.x:8000`).

*(Update the base URL in your application's API service class accordingly).*

### 5. Run the Application
Start up your Android emulator or connect a physical device via USB, then run:

```bash
flutter run
```

---

## 🚀 Usage Workflow

1. **Admin Setup**: Register an Admin account, create a new Class, and add Students.
2. **Face Enrollment**: Capture and enroll clear, frontal face images for each student through the Admin portal.
3. **Take Attendance**: Log in as an Instructor, select the class, and take a group photo.
4. **Review**: Wait for the backend to process the image, review the matched faces, make any manual corrections, and hit finalize to save attendance to the cloud!
