import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../models/class_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _firestoreService = FirestoreService();
  String? _selectedClassId;

  void _showStudentDialog({StudentModel? existingStudent}) {
    final nameController =
        TextEditingController(text: existingStudent?.fullName ?? '');
    final rollController =
        TextEditingController(text: existingStudent?.rollNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text(existingStudent == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  rollController.text.isEmpty) {
                return;
              }

              if (existingStudent == null) {
                if (_selectedClassId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a class first')),
                  );
                  return;
                }
                await _firestoreService.addStudent(StudentModel(
                  studentId: '',
                  fullName: nameController.text.trim(),
                  rollNumber: rollController.text.trim(),
                  classId: _selectedClassId!,
                ));
              } else {
                await _firestoreService
                    .updateStudent(existingStudent.studentId, {
                  'fullName': nameController.text.trim(),
                  'rollNumber': rollController.text.trim(),
                });
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(existingStudent == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Are you sure you want to delete "${student.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteStudent(
          student.studentId, student.classId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
      ),
      floatingActionButton: _selectedClassId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showStudentDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            )
          : null,
      body: Column(
        children: [
          // Class selector
          Padding(
            padding: const EdgeInsets.all(16),
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
                      child: Text(
                          '${c.className} - ${c.section.isEmpty ? "Default" : c.section}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedClassId = value);
                  },
                );
              },
            ),
          ),

          // Student list
          Expanded(
            child: _selectedClassId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Select a class to view students',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off,
                                  size: 64,
                                  color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No students in this class',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final hasEnrollment =
                              student.faceEmbeddings.isNotEmpty;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasEnrollment
                                    ? AppTheme.successColor
                                        .withValues(alpha: 0.1)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  hasEnrollment
                                      ? Icons.face
                                      : Icons.person,
                                  color: hasEnrollment
                                      ? AppTheme.successColor
                                      : Colors.grey,
                                ),
                              ),
                              title: Text(
                                student.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Roll: ${student.rollNumber} • ${hasEnrollment ? "Enrolled" : "Not enrolled"}',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20,
                                            color: AppTheme.errorColor),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color:
                                                    AppTheme.errorColor)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showStudentDialog(
                                        existingStudent: student);
                                  } else if (value == 'delete') {
                                    _deleteStudent(student);
                                  }
                                },
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
    );
  }
}
