import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';

import '../../models/attendance_session_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'attendance_review_screen.dart';

class AttendanceCaptureScreen extends StatefulWidget {
  final ClassModel classModel;
  final UserModel user;

  const AttendanceCaptureScreen({
    super.key,
    required this.classModel,
    required this.user,
  });

  @override
  State<AttendanceCaptureScreen> createState() =>
      _AttendanceCaptureScreenState();
}

class _AttendanceCaptureScreenState extends State<AttendanceCaptureScreen> {
  final _imagePicker = ImagePicker();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _apiService = ApiService();

  File? _capturedImage;
  bool _isProcessing = false;
  String _statusMessage = '';

  Future<void> _captureImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 95,
    );

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _processImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating attendance session...';
    });

    try {
      // Create session
      final session = AttendanceSessionModel(
        sessionId: '',
        classId: widget.classModel.classId,
        instructorId: widget.user.userId,
        timestamp: DateTime.now(),
      );

      final sessionId =
          await _firestoreService.createAttendanceSession(session);

      setState(() => _statusMessage = 'Uploading image...');

      // Upload image
      final imageUrl = await _storageService.uploadAttendanceImage(
        sessionId: sessionId,
        imageFile: _capturedImage!,
      );

      await _firestoreService.updateAttendanceSession(sessionId, {
        'sourceImageUrl': imageUrl,
      });

      setState(() => _statusMessage = 'Fetching enrolled students...');

      // Get enrolled students
      final studentsSnapshot = await _firestoreService
          .getStudentsInClass(widget.classModel.classId)
          .first;

      final enrolledStudents = studentsSnapshot
          .where((s) => s.faceEmbeddings.isNotEmpty)
          .map((s) => {
                'student_id': s.studentId,
                'full_name': s.fullName,
                'embeddings': s.faceEmbeddings,
              })
          .toList();

      setState(() => _statusMessage = 'Processing faces...');

      // Send to backend for recognition
      final result = await _apiService.processAttendanceImage(
        imageFile: _capturedImage!,
        classId: widget.classModel.classId,
        enrolledStudents: enrolledStudents,
      );

      // Parse results
      final recognized = (result['recognized'] as List<dynamic>?)
              ?.map((e) => RecognizedStudent.fromMap(e))
              .toList() ??
          [];

      final unresolved = (result['unresolved'] as List<dynamic>?)
              ?.map((e) => UnresolvedFace.fromMap(e))
              .toList() ??
          [];

      final detectedCount = result['detected_faces_count'] ?? 0;

      // Update session with results
      await _firestoreService.updateAttendanceSession(sessionId, {
        'detectedFacesCount': detectedCount,
        'recognizedStudents':
            recognized.map((e) => e.toMap()).toList(),
        'unresolvedFaces':
            unresolved.map((e) => e.toMap()).toList(),
      });

      // Navigate to review screen
      if (mounted) {
        final updatedSession = AttendanceSessionModel(
          sessionId: sessionId,
          classId: widget.classModel.classId,
          instructorId: widget.user.userId,
          timestamp: DateTime.now(),
          sourceImageUrl: imageUrl,
          detectedFacesCount: detectedCount,
          recognizedStudents: recognized,
          unresolvedFaces: unresolved,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AttendanceReviewScreen(
              session: updatedSession,
              classModel: widget.classModel,
              allStudents: studentsSnapshot,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Attendance'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Class info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.class_,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.classModel.className,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Section: ${widget.classModel.section.isEmpty ? "Default" : widget.classModel.section}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Capture guidance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates,
                              color: AppTheme.warningColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Capture Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• Ensure the entire class is visible',
                          style: TextStyle(fontSize: 13)),
                      Text('• Students should face the camera',
                          style: TextStyle(fontSize: 13)),
                      Text('• Avoid extreme blur or backlight',
                          style: TextStyle(fontSize: 13)),
                      Text('• Good lighting improves accuracy',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image preview
                if (_capturedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _capturedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  setState(() => _capturedImage = null);
                                },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessing ? null : _processImage,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Process Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Capture buttons
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Capture or upload a class photo',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _captureImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _captureImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 60,
                          width: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Processing Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
