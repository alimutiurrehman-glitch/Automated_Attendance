import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/attendance_session_model.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AttendanceReviewScreen extends StatefulWidget {
  final AttendanceSessionModel session;
  final ClassModel classModel;
  final List<StudentModel> allStudents;

  const AttendanceReviewScreen({
    super.key,
    required this.session,
    required this.classModel,
    required this.allStudents,
  });

  @override
  State<AttendanceReviewScreen> createState() =>
      _AttendanceReviewScreenState();
}

class _AttendanceReviewScreenState extends State<AttendanceReviewScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabController;

  // Mutable attendance state
  late Set<String> _presentStudentIds;
  late List<ManualEdit> _manualEdits;
  final Map<String, List<List<double>>> _newEmbeddingsToLearn = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize present set from recognized students
    _presentStudentIds = widget.session.recognizedStudents
        .map((r) => r.studentId)
        .toSet();
    _manualEdits = [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StudentModel> get _presentStudents {
    return widget.allStudents
        .where((s) => _presentStudentIds.contains(s.studentId))
        .toList();
  }

  List<StudentModel> get _absentStudents {
    return widget.allStudents
        .where((s) => !_presentStudentIds.contains(s.studentId))
        .toList();
  }

  void _toggleAttendance(String studentId, bool markPresent) {
    setState(() {
      if (markPresent) {
        _presentStudentIds.add(studentId);
        _manualEdits.add(ManualEdit(
          studentId: studentId,
          action: 'marked_present',
        ));
      } else {
        _presentStudentIds.remove(studentId);
        _manualEdits.add(ManualEdit(
          studentId: studentId,
          action: 'marked_absent',
        ));
      }
    });
  }

  Future<void> _finalizeAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalize Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Present: ${_presentStudents.length} students'),
            Text(
                'Absent: ${_absentStudents.length} students'),
            if (_manualEdits.isNotEmpty)
              Text(
                  'Manual corrections: ${_manualEdits.length}'),
            const SizedBox(height: 12),
            const Text('Are you sure you want to finalize?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.finalizeAttendance(
        sessionId: widget.session.sessionId,
        presentStudents: _presentStudentIds.toList(),
        absentStudents: _absentStudents.map((s) => s.studentId).toList(),
        manualEdits: _manualEdits,
      );

      // Learn from past mistakes: update student embeddings for accepted matches
      for (final entry in _newEmbeddingsToLearn.entries) {
        final studentId = entry.key;
        final newEmbeddings = entry.value;
        try {
          final student = widget.allStudents.firstWhere((s) => s.studentId == studentId);
          final updatedEmbeddings = [...student.faceEmbeddings, ...newEmbeddings];
          await _firestoreService.updateStudentEmbeddings(studentId, updatedEmbeddings);
        } catch (e) {
          debugPrint('Error updating student embeddings for learning: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance finalized successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Attendance'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.check_circle, size: 20),
              text: 'Present (${_presentStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.cancel, size: 20),
              text: 'Absent (${_absentStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.help, size: 20),
              text: 'Unresolved (${widget.session.unresolvedFaces.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryChip(
                  label: 'Detected',
                  value: '${widget.session.detectedFacesCount}',
                  color: AppTheme.primaryColor,
                ),
                _SummaryChip(
                  label: 'Recognized',
                  value: '${widget.session.recognizedStudents.length}',
                  color: AppTheme.successColor,
                ),
                _SummaryChip(
                  label: 'Total Students',
                  value: '${widget.allStudents.length}',
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Present tab
                _buildStudentList(
                  _presentStudents,
                  isPresent: true,
                ),
                // Absent tab
                _buildStudentList(
                  _absentStudents,
                  isPresent: false,
                ),
                // Unresolved tab
                _buildUnresolvedList(),
              ],
            ),
          ),

          // Finalize button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _finalizeAttendance,
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                  _isSaving ? 'Saving...' : 'Finalize Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentModel> students,
      {required bool isPresent}) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPresent ? Icons.check_circle_outline : Icons.person_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isPresent ? 'No students marked present' : 'All students are present!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];

        // Find confidence if recognized
        final recognition = widget.session.recognizedStudents
            .where((r) => r.studentId == student.studentId)
            .firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color:
                    isPresent ? AppTheme.successColor : Colors.grey,
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Roll: ${student.rollNumber}${recognition != null ? " • Confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%" : ""}',
            ),
            trailing: Switch(
              value: isPresent,
              activeThumbColor: AppTheme.successColor,
              onChanged: (value) {
                _toggleAttendance(student.studentId, value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnresolvedList() {
    final unresolved = widget.session.unresolvedFaces;

    if (unresolved.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_satisfied,
                size: 48, color: AppTheme.successColor),
            SizedBox(height: 12),
            Text('No unresolved faces',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: unresolved.length,
      itemBuilder: (context, index) {
        final face = unresolved[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        image: face.faceImageUrl != null && face.faceImageUrl!.contains(',')
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(face.faceImageUrl!.split(',').last)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: face.faceImageUrl == null || !face.faceImageUrl!.contains(',')
                          ? const Icon(Icons.help, color: AppTheme.warningColor)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unresolved Face #${face.faceIndex + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          if (face.bestMatchStudentId != null)
                            Text(
                              'Best match confidence: ${((face.bestMatchConfidence ?? 0) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (face.bestMatchStudentId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _toggleAttendance(
                                face.bestMatchStudentId!, true);
                                
                            // Save embedding to learn from mistake
                            if (face.embedding != null) {
                              _newEmbeddingsToLearn.putIfAbsent(face.bestMatchStudentId!, () => []);
                              _newEmbeddingsToLearn[face.bestMatchStudentId!]!.add(face.embedding!);
                            }

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Student marked present'),
                                backgroundColor:
                                    AppTheme.successColor,
                              ),
                            );
                          },
                          child: const Text('Accept Match'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text('Match rejected'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(
                                color: AppTheme.errorColor),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
