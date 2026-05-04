import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/attendance_session_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CLASS OPERATIONS ====================

  /// Create a new class
  Future<String> createClass(ClassModel classModel) async {
    final ref = await _firestore.collection('classes').add(classModel.toMap());
    return ref.id;
  }

  /// Get all classes
  Stream<List<ClassModel>> getClasses() {
    return _firestore.collection('classes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get classes assigned to an instructor
  Stream<List<ClassModel>> getClassesForInstructor(String instructorId) {
    return _firestore
        .collection('classes')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update a class
  Future<void> updateClass(String classId, Map<String, dynamic> data) async {
    await _firestore.collection('classes').doc(classId).update(data);
  }

  /// Delete a class
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  // ==================== STUDENT OPERATIONS ====================

  /// Add a student
  Future<String> addStudent(StudentModel student) async {
    final ref = await _firestore.collection('students').add(student.toMap());

    // Add student to class's student list
    await _firestore.collection('classes').doc(student.classId).update({
      'studentIds': FieldValue.arrayUnion([ref.id]),
    });

    return ref.id;
  }

  /// Get students in a class
  Stream<List<StudentModel>> getStudentsInClass(String classId) {
    return _firestore
        .collection('students')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e) {
        throw Exception("Error parsing student data: $e");
      }
    });
  }

  /// Get a single student
  Future<StudentModel?> getStudent(String studentId) async {
    final doc = await _firestore.collection('students').doc(studentId).get();
    if (doc.exists) {
      return StudentModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Update a student
  Future<void> updateStudent(
      String studentId, Map<String, dynamic> data) async {
    await _firestore.collection('students').doc(studentId).update(data);
  }

  /// Delete a student
  Future<void> deleteStudent(String studentId, String classId) async {
    await _firestore.collection('students').doc(studentId).delete();

    // Remove from class student list
    await _firestore.collection('classes').doc(classId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  /// Update student face embeddings
  Future<void> updateStudentEmbeddings(
      String studentId, List<List<double>> embeddings) async {
    await _firestore.collection('students').doc(studentId).update({
      'faceEmbeddings': embeddings.map((e) => jsonEncode(e)).toList(),
    });
  }

  /// Update student enrollment images
  Future<void> updateEnrollmentImages(
      String studentId, List<String> imageUrls) async {
    await _firestore.collection('students').doc(studentId).update({
      'enrollmentImages': imageUrls,
    });
  }

  // ==================== ATTENDANCE SESSION OPERATIONS ====================

  /// Create an attendance session
  Future<String> createAttendanceSession(
      AttendanceSessionModel session) async {
    final ref =
        await _firestore.collection('attendanceSessions').add(session.toMap());
    return ref.id;
  }

  /// Update an attendance session
  Future<void> updateAttendanceSession(
      String sessionId, Map<String, dynamic> data) async {
    await _firestore
        .collection('attendanceSessions')
        .doc(sessionId)
        .update(data);
  }

  /// Finalize an attendance session
  Future<void> finalizeAttendance({
    required String sessionId,
    required List<String> presentStudents,
    required List<String> absentStudents,
    required List<ManualEdit> manualEdits,
  }) async {
    await _firestore
        .collection('attendanceSessions')
        .doc(sessionId)
        .update({
      'finalPresentStudents': presentStudents,
      'finalAbsentStudents': absentStudents,
      'manualEdits': manualEdits.map((e) => e.toMap()).toList(),
      'isFinalized': true,
    });
  }

  /// Get attendance sessions for a class
  Stream<List<AttendanceSessionModel>> getAttendanceSessions(String classId) {
    return _firestore
        .collection('attendanceSessions')
        .where('classId', isEqualTo: classId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => AttendanceSessionModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e) {
        throw Exception("Error parsing attendance session: $e");
      }
    });
  }

  /// Get all attendance sessions (admin view)
  Stream<List<AttendanceSessionModel>> getAllAttendanceSessions() {
    return _firestore
        .collection('attendanceSessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceSessionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get a single attendance session
  Future<AttendanceSessionModel?> getAttendanceSession(
      String sessionId) async {
    final doc = await _firestore
        .collection('attendanceSessions')
        .doc(sessionId)
        .get();
    if (doc.exists) {
      return AttendanceSessionModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ==================== USER OPERATIONS ====================

  /// Get all instructors
  Stream<List<UserModel>> getInstructors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'instructor')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
