import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_session_model.dart';
import '../models/student_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final bool isAdmin;
  final String userId;
  final String? classId;

  const AttendanceHistoryScreen({
    super.key,
    required this.isAdmin,
    required this.userId,
    this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: StreamBuilder<List<AttendanceSessionModel>>(
        stream: isAdmin
            ? firestoreService.getAllAttendanceSessions()
            : classId != null
                ? firestoreService.getAttendanceSessions(classId!)
                : firestoreService.getAllAttendanceSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No attendance records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _SessionDetailScreen(
                          session: session,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: session.isFinalized
                                    ? AppTheme.successColor.withValues(alpha: 0.1)
                                    : AppTheme.warningColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                session.isFinalized
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: session.isFinalized
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(session.timestamp),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    session.isFinalized
                                        ? 'Finalized'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: session.isFinalized
                                          ? AppTheme.successColor
                                          : AppTheme.warningColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.face,
                              label: '${session.detectedFacesCount} detected',
                            ),
                            const SizedBox(width: 16),
                            _InfoChip(
                              icon: Icons.check,
                              label: '${session.finalPresentStudents.length} present',
                            ),
                            const SizedBox(width: 16),
                            _InfoChip(
                              icon: Icons.close,
                              label: '${session.finalAbsentStudents.length} absent',
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
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

// Session detail screen
class _SessionDetailScreen extends StatelessWidget {
  final AttendanceSessionModel session;

  const _SessionDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(session.timestamp),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard(
                          value: '${session.detectedFacesCount}',
                          label: 'Faces Detected',
                          color: AppTheme.primaryColor,
                        ),
                        _StatCard(
                          value: '${session.finalPresentStudents.length}',
                          label: 'Present',
                          color: AppTheme.successColor,
                        ),
                        _StatCard(
                          value: '${session.finalAbsentStudents.length}',
                          label: 'Absent',
                          color: AppTheme.errorColor,
                        ),
                      ],
                    ),
                    if (session.manualEdits.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        '${session.manualEdits.length} manual correction(s) made',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Present students
            if (session.finalPresentStudents.isNotEmpty) ...[
              const Text(
                'Present Students',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.finalPresentStudents.map((studentId) {
                return FutureBuilder<StudentModel?>(
                  future: firestoreService.getStudent(studentId),
                  builder: (context, snapshot) {
                    final student = snapshot.data;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          radius: 16,
                          child: Icon(Icons.check,
                              size: 16, color: AppTheme.successColor),
                        ),
                        title: Text(student?.fullName ?? studentId),
                        subtitle: student != null
                            ? Text('Roll: ${student.rollNumber}')
                            : null,
                      ),
                    );
                  },
                );
              }),
            ],
            const SizedBox(height: 16),

            // Absent students
            if (session.finalAbsentStudents.isNotEmpty) ...[
              const Text(
                'Absent Students',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.finalAbsentStudents.map((studentId) {
                return FutureBuilder<StudentModel?>(
                  future: firestoreService.getStudent(studentId),
                  builder: (context, snapshot) {
                    final student = snapshot.data;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFEBEE),
                          radius: 16,
                          child: Icon(Icons.close,
                              size: 16, color: AppTheme.errorColor),
                        ),
                        title: Text(student?.fullName ?? studentId),
                        subtitle: student != null
                            ? Text('Roll: ${student.rollNumber}')
                            : null,
                      ),
                    );
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
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
