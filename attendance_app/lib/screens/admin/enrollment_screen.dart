import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/student_model.dart';
import '../../models/class_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  String? _selectedClassId;
  bool _isProcessing = false;

  Future<void> _enrollStudent(StudentModel student) async {
    // Pick image
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (pickedFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final imageFile = File(pickedFile.path);

      // Upload image to storage
      final imageUrl = await _storageService.uploadEnrollmentImage(
        studentId: student.studentId,
        imageFile: imageFile,
      );

      // Generate embedding via backend
      final embedding = await _apiService.generateEmbedding(imageFile);

      // Update student record
      final updatedImages = [...student.enrollmentImages, imageUrl];
      final updatedEmbeddings = [...student.faceEmbeddings, embedding];

      await _firestoreService.updateEnrollmentImages(
          student.studentId, updatedImages);
      await _firestoreService.updateStudentEmbeddings(
          student.studentId, updatedEmbeddings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} enrolled successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload or capture a clear frontal face image for each student. Good lighting and minimal blur are required.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Class selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<ClassModel>>(
                  stream: _firestoreService.getClasses(),
                  builder: (context, snapshot) {
                    final classes = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: classes.map((c) {
                        return DropdownMenuItem(
                          value: c.classId,
                          child: Text('${c.className} - ${c.section}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClassId = value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Students list
              Expanded(
                child: _selectedClassId == null
                    ? const Center(
                        child: Text(
                          'Select a class to enroll students',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : StreamBuilder<List<StudentModel>>(
                        stream: _firestoreService
                            .getStudentsInClass(_selectedClassId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final students = snapshot.data ?? [];

                          if (students.isEmpty) {
                            return const Center(
                              child: Text('No students in this class'),
                            );
                          }

                          return ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final isEnrolled =
                                  student.faceEmbeddings.isNotEmpty;
                              final imageCount =
                                  student.enrollmentImages.length;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: isEnrolled
                                            ? AppTheme.successColor
                                                .withValues(alpha: 0.1)
                                            : Colors.grey.shade200,
                                        backgroundImage:
                                            student.enrollmentImages
                                                    .isNotEmpty
                                                ? NetworkImage(student
                                                    .enrollmentImages.last)
                                                : null,
                                        child:
                                            student.enrollmentImages.isEmpty
                                                ? Icon(
                                                    Icons.person,
                                                    color: isEnrolled
                                                        ? AppTheme
                                                            .successColor
                                                        : Colors.grey,
                                                  )
                                                : null,
                                      ),
                                      if (isEnrolled)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.successColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    student.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Roll: ${student.rollNumber} • $imageCount image(s)',
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _enrollStudent(student),
                                    icon: Icon(
                                      isEnrolled
                                          ? Icons.add_a_photo
                                          : Icons.face_retouching_natural,
                                      size: 18,
                                    ),
                                    label: Text(
                                        isEnrolled ? 'Add' : 'Enroll'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEnrolled
                                          ? AppTheme.accentColor
                                          : AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing face enrollment...',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Generating face embedding',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
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
