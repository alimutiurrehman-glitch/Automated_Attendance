# Product Requirements Document (PRD)

## Product Title
**Automated Classroom Attendance Marker**

## Document Purpose
This PRD defines the product requirements for a semester project: an Android-based automated attendance system that enables an instructor to capture a group photo of a classroom using a phone camera and automatically mark attendance using computer vision and facial recognition. The document is written to be implementation-oriented so an AI coding agent or engineering team can use it directly to design and build the system.

---

## 1. Product Overview

### 1.1 Summary
The product is an **Android application** used by instructors to take a group photo of a class. The system detects faces in the image, recognizes enrolled students, and marks those students as **Present** for that session. The instructor can review results and manually correct mistakes before finalizing attendance.

### 1.2 Initial Scope
This version is a **demo-ready prototype** intended to work for:
- One classroom
- One class section
- Approximately **30–60 students**
- Manual student enrollment
- Instructor and admin roles only

### 1.3 Primary Goal
Reduce the time and manual effort required to mark attendance while demonstrating a practical application of computer vision and facial recognition in an academic classroom setting.

### 1.4 Core Product Value
- Fast attendance marking from a single group photo
- Higher convenience than roll call or manual entry
- Manual correction to reduce risk of false marking
- Demo-friendly and technically feasible for a semester project

---

## 2. Users and Roles

### 2.1 Instructor
The instructor uses the Android app to:
- Log in
- Select a course/class session
- Capture or upload a classroom image
- Run attendance detection
- Review recognized students
- Manually correct attendance
- Finalize and save attendance

### 2.2 Admin
The admin manages setup and data:
- Create/manage instructor accounts
- Create/manage classes
- Add student records
- Manually enroll student face data
- View attendance history and reports

---

## 3. Problem Statement
Traditional classroom attendance takes time, interrupts teaching, and is prone to human error. In medium-sized classrooms, manual roll calls are inefficient and repetitive. An automated system that recognizes students from a class group photo can streamline this process, but must remain accurate enough for real classroom use and provide manual correction when recognition confidence is imperfect.

---

## 4. Goals and Non-Goals

### 4.1 Goals
- Build an Android demo application for automated attendance marking.
- Detect and recognize faces from a single classroom group photo.
- Mark recognized students as present.
- Support manual correction before final submission.
- Store attendance records in Firebase.
- Achieve strong performance in varied classroom lighting conditions.
- Prioritize **accuracy** above secondary concerns like advanced scale or feature breadth.

### 4.2 Non-Goals (Initial Version)
- University-wide deployment
- Real-time video attendance tracking
- Passive background attendance monitoring
- Anti-spoofing at production security level
- Multi-classroom concurrent scaling
- iOS support
- Automatic integration with university ERP/SIS systems
- Perfect recognition under all conditions without fallback review

---

## 5. Success Metrics

### 5.1 Primary Success Metrics
- **Recognition precision:** At least **95%** for clearly visible enrolled students in controlled classroom demo conditions.
- **Attendance workflow completion time:** Instructor can capture, review, and finalize attendance within **60 seconds** for a class of 30–60 students.
- **Detection coverage:** At least **90%** of clearly visible faces in a properly captured image are detected.
- **Manual correction completion time:** Instructor can fix missed/wrong entries within **2 minutes**.

### 5.2 Secondary Metrics
- App crash-free session rate above **95%** during demo testing
- Face enrollment completion for all students in the sample class
- Attendance records saved successfully to backend in **99%** of test cases with connectivity

---

## 6. Key Assumptions
- Students are enrolled manually before attendance sessions begin.
- Each student has at least one clear face image available for enrollment.
- The class size remains between 30 and 60 students for the initial prototype.
- The instructor captures a reasonably clear image where most faces are visible.
- Internet connectivity is available for Firebase-backed operations unless optional offline support is later added.

---

## 7. Functional Requirements

## 7.1 Authentication and Access Control
### Requirements
- The system must support login for **Instructor** and **Admin** roles.
- The system must restrict features based on user role.
- The app must maintain session state until logout or expiration.

### Acceptance Criteria
- Instructor can only access assigned classes and attendance workflows.
- Admin can access setup, enrollment, and historical attendance management.

---

## 7.2 Class and Student Management
### Requirements
- Admin must be able to create classes/sections.
- Admin must be able to add, edit, and remove student records.
- Each student record must include:
  - Student ID
  - Full name
  - Class/section
  - Enrollment face images/templates

### Acceptance Criteria
- Admin can create a class and add 30–60 students.
- Student records are stored in Firebase and retrievable in the app.

---

## 7.3 Manual Face Enrollment
### Requirements
- Admin must be able to manually enroll students.
- Enrollment should support uploading or capturing one or more face images per student.
- The system should preprocess and store face embeddings/templates for matching.
- The system should validate image quality during enrollment.

### Acceptance Criteria
- Admin can enroll a student using at least one clear frontal face image.
- System rejects unusable enrollment images with clear guidance.
- Enrollment data is linked correctly to the student profile.

---

## 7.4 Attendance Session Creation
### Requirements
- Instructor must be able to select a class/course before capturing attendance.
- The system must create an attendance session with timestamp and class metadata.
- The instructor must be able to capture a photo using the Android camera or select an image from device storage.

### Acceptance Criteria
- Instructor can start a session in fewer than 3 taps after login.
- Session contains date, time, class ID, instructor ID, and source image metadata.

---

## 7.5 Face Detection
### Requirements
- The system must detect multiple faces in a single classroom image.
- The system should work under **varied classroom lighting conditions**, including bright, dim, uneven, and backlit indoor lighting as much as technically feasible.
- The system should preprocess images using techniques such as resizing, normalization, contrast enhancement, denoising, or exposure correction when needed.

### Acceptance Criteria
- System detects visible faces from a classroom image containing 30–60 students with acceptable latency.
- System provides a warning if image quality is too poor for reliable attendance.

---

## 7.6 Face Recognition and Matching
### Requirements
- The system must compare detected faces against enrolled student templates.
- A student should be marked **Present** if their face is recognized from the group photo.
- Matching must use a configurable confidence threshold.
- The system must avoid duplicate marking of the same student in one session.
- Unrecognized or low-confidence detections should remain unresolved for manual review.

### Acceptance Criteria
- Recognized students are automatically marked present.
- Low-confidence matches are surfaced to the instructor for review.
- No student is marked present more than once in the same attendance session.

---

## 7.7 Instructor Review and Manual Correction
### Requirements
- Instructor must be able to view:
  - Recognized students
  - Unrecognized faces
  - Absent students list
- Instructor must be able to manually:
  - Mark present
  - Mark absent
  - Correct wrong matches
  - Confirm or reject low-confidence matches
- Attendance must not be finalized until instructor confirms.

### Acceptance Criteria
- Instructor can edit attendance before submission.
- Final attendance state reflects the edited list, not only the model output.

---

## 7.8 Attendance Finalization and Storage
### Requirements
- Final attendance must be stored in Firebase.
- The record must include:
  - Session ID
  - Class ID
  - Instructor ID
  - Timestamp
  - Present students
  - Absent students
  - Manual corrections made
  - Original image reference (optional but recommended)

### Acceptance Criteria
- Attendance can be retrieved later by admin or instructor.
- Saved records remain consistent after app restart.

---

## 7.9 Attendance History and Reporting
### Requirements
- Instructor must be able to view attendance history for assigned classes.
- Admin must be able to view attendance history across all classes.
- The system should show per-session and per-student attendance summaries.

### Acceptance Criteria
- User can open a past session and inspect attendance results.
- Admin can see which students were marked present/absent over time.

---

## 8. User Stories

### Instructor Stories
- As an instructor, I want to log in and select my class so I can quickly start attendance.
- As an instructor, I want to capture one group photo of the classroom so I do not need to call roll manually.
- As an instructor, I want the app to recognize students automatically so attendance is marked faster.
- As an instructor, I want to review and manually correct results so I stay in control of final attendance.
- As an instructor, I want attendance saved to the cloud so I can access records later.

### Admin Stories
- As an admin, I want to create classes and student lists so the system can be used for real sessions.
- As an admin, I want to manually enroll student faces so recognition has known references.
- As an admin, I want to review attendance history so I can manage records and verify performance.

---

## 9. User Flow

### 9.1 Admin Enrollment Flow
1. Admin logs in
2. Admin creates class/section
3. Admin adds student records
4. Admin uploads/captures student face images
5. System preprocesses faces and stores templates
6. Enrollment status is confirmed

### 9.2 Instructor Attendance Flow
1. Instructor logs in
2. Instructor selects class
3. Instructor starts attendance session
4. Instructor captures group photo
5. System processes image
6. System detects faces
7. System recognizes enrolled students
8. Present list is auto-generated
9. Instructor reviews low-confidence/unmatched results
10. Instructor manually corrects attendance
11. Instructor finalizes attendance
12. System saves attendance in Firebase

---

## 10. Screens and UI Requirements

### 10.1 Login Screen
- Email/username
- Password
- Role-aware login handling

### 10.2 Instructor Dashboard
- Assigned classes list
- Recent attendance sessions
- Start attendance button

### 10.3 Admin Dashboard
- Classes
- Students
- Enrollment
- Attendance history

### 10.4 Student Enrollment Screen
- Add/edit student info
- Capture/upload images
- Enrollment status/quality feedback

### 10.5 Attendance Capture Screen
- Camera preview
- Capture photo button
- Upload from gallery option
- Capture guidance overlay (optional)

### 10.6 Attendance Review Screen
- Recognized students list
- Unrecognized detections
- Absent students list
- Manual present/absent toggles
- Finalize button

### 10.7 Attendance History Screen
- Session list by date/class
- Student-wise attendance summary

---

## 11. Non-Functional Requirements

### 11.1 Accuracy
- Accuracy is the top priority.
- Recognition must be tuned for high precision to avoid false positives.
- When uncertain, the system should prefer review over automatic marking.

### 11.2 Performance
- Image processing should complete within **10–20 seconds** on typical demo hardware or backend-assisted flow.
- Full attendance workflow should stay within **60 seconds** for normal conditions.

### 11.3 Reliability
- The system should not lose attendance records after final confirmation.
- Errors should be recoverable with useful messages.

### 11.4 Usability
- The workflow must be simple enough for an instructor to use with minimal training.
- Manual correction must be fast and clear.

### 11.5 Security and Privacy
- Student images and embeddings must be stored securely.
- Access must be role-restricted.
- Attendance data must only be visible to authorized users.
- The project should include a visible statement that biometric data is sensitive and used only for attendance purposes in the prototype.

### 11.6 Lighting Robustness
- The system should function across **varied classroom lighting conditions** as far as technically feasible for a semester prototype.
- It should include preprocessing and capture guidance to improve results in low light, harsh light, uneven light, and mild shadows.
- If lighting conditions make recognition unreliable, the app should warn the instructor and allow recapture.

### 11.7 Maintainability
- Codebase should be modular and documented so an AI agent or developer can extend it.
- Models, thresholds, and backend configuration should be configurable.

---

## 12. Edge Cases and Failure Handling

### Edge Cases
- Some students are partially occluded in the group photo
- Students are not facing the camera
- Multiple similar-looking faces are detected
- Same student appears in enrollment image but recognition confidence is low
- Some students are outside frame
- Motion blur in captured photo
- Very bright background or dim lighting
- Internet connectivity interruption while saving
- A student is enrolled with poor-quality face data

### Required Handling
- Show image quality warning for poor captures
- Allow instructor to retake image
- Surface unresolved detections for manual handling
- Allow manual marking even if recognition fails
- Prevent final attendance corruption if save operation fails
- Retry cloud sync or show local pending state if offline support is later added

---

## 13. Technical Approach

### 13.1 Suggested Stack
- **Mobile App:** Flutter (Android target)
- **Backend/Data Store:** Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **CV/Recognition Service:** Python
  - OpenCV for image preprocessing/detection pipeline support
  - Face recognition model/library using TensorFlow, PyTorch, FaceNet, ArcFace, InsightFace, or another suitable embedding-based approach

### 13.2 Recommended Architecture
**Option A: Hybrid mobile + backend inference**
- Flutter app captures image
- Image uploaded securely to backend or storage
- Python service performs detection and recognition
- Result returned to app for review
- Final attendance stored in Firebase

This is the preferred architecture for the project because:
- Python CV ecosystem is stronger and easier for experimentation
- Flutter remains focused on mobile UX
- Recognition logic stays centralized and easier to update

### 13.3 High-Level Components
- Android UI (Flutter)
- Firebase auth and storage layer
- Student/class data store
- Python face detection and recognition service
- Attendance decision engine
- Review/correction interface

---

## 14. Data Model (Initial)

### 14.1 Users
- user_id
- name
- email
- role (`admin`, `instructor`)

### 14.2 Classes
- class_id
- class_name
- section
- instructor_id
- student_ids[]

### 14.3 Students
- student_id
- full_name
- roll_number
- class_id
- enrollment_images[]
- face_embeddings[]
- created_at

### 14.4 Attendance Sessions
- session_id
- class_id
- instructor_id
- timestamp
- source_image_url
- detected_faces_count
- recognized_students[]
- unresolved_faces[]
- final_present_students[]
- final_absent_students[]
- manual_edits[]

---

## 15. Recognition Rules

### Initial Rule
- Mark student **Present** if their face is recognized in one group photo.

### Additional Rules
- One recognized face can map to only one enrolled student.
- One student can only be marked present once per session.
- Low-confidence predictions should not be auto-finalized without instructor review.
- Students not recognized remain absent until manually corrected.

---

## 16. Quality Requirements for Enrollment and Capture

### Enrollment Quality
- Clear frontal face
- Good lighting
- Minimal blur
- No heavy occlusion
- Prefer multiple images if feasible

### Classroom Capture Guidance
- Entire class should be visible
- Faces should be reasonably front-facing
- Avoid extreme blur
- Encourage sufficient light
- Avoid extreme backlight from windows when possible

---

## 17. Risks and Mitigations

### Risk 1: Lighting variability reduces recognition quality
**Mitigation:**
- Preprocessing pipeline
- Capture guidance
- Retake warnings
- Manual correction screen
- Evaluate with multiple classroom lighting conditions during testing

### Risk 2: Occlusion and pose issues in group photos
**Mitigation:**
- Encourage front-facing seating during demo
- Allow recapture
- Manual correction fallback

### Risk 3: False positives cause incorrect attendance
**Mitigation:**
- Conservative confidence threshold
- Instructor review before finalization
- Log manual overrides for analysis

### Risk 4: Manual enrollment data is poor
**Mitigation:**
- Add image quality validation
- Require re-enrollment if quality is too low

### Risk 5: Demo performance is too slow
**Mitigation:**
- Limit scope to one class of 30–60 students
- Use precomputed embeddings
- Optimize backend matching pipeline

---

## 18. Testing Strategy

### 18.1 Functional Testing
- Login and role access
- Student enrollment
- Class creation
- Attendance capture
- Detection and recognition
- Manual correction
- Save and retrieve attendance

### 18.2 Accuracy Testing
- Test with multiple classroom images
- Test under bright, dim, uneven, and mixed lighting
- Test with partial occlusions and different seating positions
- Measure precision, recall, false positives, and false negatives

### 18.3 Usability Testing
- Instructor completes attendance without technical help
- Admin enrolls a full sample class successfully

### 18.4 Performance Testing
- Measure time from capture to review-ready output
- Measure save latency to Firebase

---

## 19. Milestones

### Milestone 1: Project Setup
- Finalize architecture
- Set up Flutter app
- Set up Firebase
- Set up Python service skeleton

### Milestone 2: Admin Module
- Authentication
- Class management
- Student management
- Manual enrollment workflow

### Milestone 3: Attendance Engine
- Photo capture/upload
- Face detection
- Face recognition and matching
- Result response API

### Milestone 4: Instructor Review Flow
- Attendance review UI
- Manual correction
- Finalize and save attendance

### Milestone 5: Testing and Demo Readiness
- Accuracy tuning
- Lighting-condition tests
- Bug fixes
- Demo dataset preparation

---

## 20. Open Questions for Future Versions
- Should multiple photos be allowed for better recognition coverage?
- Should the app support offline attendance with delayed sync?
- Should liveness/spoof detection be added later?
- Should students be able to view their attendance records?
- Should automated timetable/session scheduling be added?

---

## 21. Build Guidance for an AI Agent

### Implementation Priorities
1. Build role-based authentication
2. Build admin flows for class + student setup
3. Build student manual enrollment and embedding generation
4. Build attendance session creation from mobile app
5. Build multi-face detection pipeline
6. Build recognition pipeline against enrolled students
7. Build instructor review and correction UI
8. Build Firebase save/retrieval flows
9. Add capture guidance, warnings, and error handling
10. Tune thresholds and validate on demo data

### Engineering Priorities
- Prefer precision over aggressive auto-marking
- Keep modules independent and testable
- Log recognition confidence and manual edits for debugging
- Make thresholds configurable
- Store original and processed metadata where useful for evaluation

---

## 22. Final Scope Statement
The first release of the Automated Classroom Attendance Marker is a demo-focused Android application for instructors and admins. It supports manual enrollment of 30–60 students, attendance marking from a single group classroom photo using facial recognition, manual correction before finalization, Firebase-based storage, and robust handling of varied classroom lighting conditions to the extent feasible for a semester project.

