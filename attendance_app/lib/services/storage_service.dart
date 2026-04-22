import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload an enrollment image for a student
  Future<String> uploadEnrollmentImage({
    required String studentId,
    required File imageFile,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref()
        .child('enrollments')
        .child(studentId)
        .child(fileName);

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload an attendance session image
  Future<String> uploadAttendanceImage({
    required String sessionId,
    required File imageFile,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref()
        .child('attendance_images')
        .child(sessionId)
        .child(fileName);

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete a file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // File may already be deleted
    }
  }

  /// Delete all enrollment images for a student
  Future<void> deleteEnrollmentImages(String studentId) async {
    try {
      final ref = _storage.ref().child('enrollments').child(studentId);
      final result = await ref.listAll();
      for (var item in result.items) {
        await item.delete();
      }
    } catch (e) {
      // Directory may not exist
    }
  }
}
