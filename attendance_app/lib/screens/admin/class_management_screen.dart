import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final _firestoreService = FirestoreService();

  void _showClassDialog({ClassModel? existingClass}) {
    final nameController =
        TextEditingController(text: existingClass?.className ?? '');
    final sectionController =
        TextEditingController(text: existingClass?.section ?? '');
    String? selectedInstructorId = existingClass?.instructorId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              existingClass == null ? 'Create Class' : 'Edit Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'e.g., DIP - Digital Image Processing',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    hintText: 'e.g., A, B, Morning',
                  ),
                ),
                const SizedBox(height: 16),
                // Instructor dropdown
                StreamBuilder<List<UserModel>>(
                  stream: _firestoreService.getInstructors(),
                  builder: (context, snapshot) {
                    final instructors = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedInstructorId,
                      decoration: const InputDecoration(
                        labelText: 'Instructor',
                      ),
                      items: instructors.map((i) {
                        return DropdownMenuItem(
                          value: i.userId,
                          child: Text(i.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInstructorId = value;
                        });
                      },
                    );
                  },
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
                if (nameController.text.isEmpty) return;

                if (existingClass == null) {
                  await _firestoreService.createClass(ClassModel(
                    classId: '',
                    className: nameController.text.trim(),
                    section: sectionController.text.trim(),
                    instructorId: selectedInstructorId ?? '',
                  ));
                } else {
                  await _firestoreService
                      .updateClass(existingClass.classId, {
                    'className': nameController.text.trim(),
                    'section': sectionController.text.trim(),
                    'instructorId': selectedInstructorId ?? '',
                  });
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(existingClass == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
            'Are you sure you want to delete "${classModel.className}"? This will not delete associated students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteClass(classModel.classId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _firestoreService.getClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No classes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to create your first class',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final cls = classes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.class_,
                        color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    cls.className,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Section: ${cls.section.isEmpty ? "N/A" : cls.section} • ${cls.studentIds.length} students',
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
                            Icon(Icons.delete, size: 20,
                                color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('Delete',
                                style:
                                    TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showClassDialog(existingClass: cls);
                      } else if (value == 'delete') {
                        _deleteClass(cls);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
