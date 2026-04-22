class ClassModel {
  final String classId;
  final String className;
  final String section;
  final String instructorId;
  final List<String> studentIds;

  ClassModel({
    required this.classId,
    required this.className,
    required this.section,
    required this.instructorId,
    this.studentIds = const [],
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassModel(
      classId: id,
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      instructorId: map['instructorId'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'section': section,
      'instructorId': instructorId,
      'studentIds': studentIds,
    };
  }

  ClassModel copyWith({
    String? classId,
    String? className,
    String? section,
    String? instructorId,
    List<String>? studentIds,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      instructorId: instructorId ?? this.instructorId,
      studentIds: studentIds ?? this.studentIds,
    );
  }
}
