import 'package:cloud_firestore/cloud_firestore.dart';

class ManualEdit {
  final String studentId;
  final String action; // 'marked_present', 'marked_absent', 'corrected_match'
  final String? reason;

  ManualEdit({
    required this.studentId,
    required this.action,
    this.reason,
  });

  factory ManualEdit.fromMap(Map<String, dynamic> map) {
    return ManualEdit(
      studentId: map['studentId'] ?? '',
      action: map['action'] ?? '',
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'action': action,
      if (reason != null) 'reason': reason,
    };
  }
}

class RecognizedStudent {
  final String studentId;
  final double confidence;

  RecognizedStudent({
    required this.studentId,
    required this.confidence,
  });

  factory RecognizedStudent.fromMap(Map<String, dynamic> map) {
    return RecognizedStudent(
      studentId: map['studentId'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'confidence': confidence,
    };
  }
}

class UnresolvedFace {
  final int faceIndex;
  final double? bestMatchConfidence;
  final String? bestMatchStudentId;
  final String? faceImageUrl;
  final List<double>? embedding;

  UnresolvedFace({
    required this.faceIndex,
    this.bestMatchConfidence,
    this.bestMatchStudentId,
    this.faceImageUrl,
    this.embedding,
  });

  factory UnresolvedFace.fromMap(Map<String, dynamic> map) {
    return UnresolvedFace(
      faceIndex: map['faceIndex'] ?? 0,
      bestMatchConfidence: map['bestMatchConfidence']?.toDouble(),
      bestMatchStudentId: map['bestMatchStudentId'],
      faceImageUrl: map['faceImageUrl'],
      embedding: (map['embedding'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'faceIndex': faceIndex,
      if (bestMatchConfidence != null)
        'bestMatchConfidence': bestMatchConfidence,
      if (bestMatchStudentId != null)
        'bestMatchStudentId': bestMatchStudentId,
      if (faceImageUrl != null) 'faceImageUrl': faceImageUrl,
      if (embedding != null) 'embedding': embedding,
    };
  }
}

class AttendanceSessionModel {
  final String sessionId;
  final String classId;
  final String instructorId;
  final DateTime timestamp;
  final String? sourceImageUrl;
  final int detectedFacesCount;
  final List<RecognizedStudent> recognizedStudents;
  final List<UnresolvedFace> unresolvedFaces;
  final List<String> finalPresentStudents;
  final List<String> finalAbsentStudents;
  final List<ManualEdit> manualEdits;
  final bool isFinalized;

  AttendanceSessionModel({
    required this.sessionId,
    required this.classId,
    required this.instructorId,
    required this.timestamp,
    this.sourceImageUrl,
    this.detectedFacesCount = 0,
    this.recognizedStudents = const [],
    this.unresolvedFaces = const [],
    this.finalPresentStudents = const [],
    this.finalAbsentStudents = const [],
    this.manualEdits = const [],
    this.isFinalized = false,
  });

  factory AttendanceSessionModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse timestamp: may be a Firestore Timestamp (app) or ISO string
    DateTime parsedTimestamp = DateTime.now();
    final rawTimestamp = map['timestamp'];
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    return AttendanceSessionModel(
      sessionId: id,
      classId: map['classId'] ?? '',
      instructorId: map['instructorId'] ?? '',
      timestamp: parsedTimestamp,
      sourceImageUrl: map['sourceImageUrl'],
      detectedFacesCount: map['detectedFacesCount'] ?? 0,
      recognizedStudents: (map['recognizedStudents'] as List<dynamic>?)
              ?.map((e) => RecognizedStudent.fromMap(e))
              .toList() ??
          [],
      unresolvedFaces: (map['unresolvedFaces'] as List<dynamic>?)
              ?.map((e) => UnresolvedFace.fromMap(e))
              .toList() ??
          [],
      finalPresentStudents:
          List<String>.from(map['finalPresentStudents'] ?? []),
      finalAbsentStudents: List<String>.from(map['finalAbsentStudents'] ?? []),
      manualEdits: (map['manualEdits'] as List<dynamic>?)
              ?.map((e) => ManualEdit.fromMap(e))
              .toList() ??
          [],
      isFinalized: map['isFinalized'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'instructorId': instructorId,
      'timestamp': Timestamp.fromDate(timestamp),
      if (sourceImageUrl != null) 'sourceImageUrl': sourceImageUrl,
      'detectedFacesCount': detectedFacesCount,
      'recognizedStudents':
          recognizedStudents.map((e) => e.toMap()).toList(),
      'unresolvedFaces': unresolvedFaces.map((e) => e.toMap()).toList(),
      'finalPresentStudents': finalPresentStudents,
      'finalAbsentStudents': finalAbsentStudents,
      'manualEdits': manualEdits.map((e) => e.toMap()).toList(),
      'isFinalized': isFinalized,
    };
  }

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? classId,
    String? instructorId,
    DateTime? timestamp,
    String? sourceImageUrl,
    int? detectedFacesCount,
    List<RecognizedStudent>? recognizedStudents,
    List<UnresolvedFace>? unresolvedFaces,
    List<String>? finalPresentStudents,
    List<String>? finalAbsentStudents,
    List<ManualEdit>? manualEdits,
    bool? isFinalized,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      classId: classId ?? this.classId,
      instructorId: instructorId ?? this.instructorId,
      timestamp: timestamp ?? this.timestamp,
      sourceImageUrl: sourceImageUrl ?? this.sourceImageUrl,
      detectedFacesCount: detectedFacesCount ?? this.detectedFacesCount,
      recognizedStudents: recognizedStudents ?? this.recognizedStudents,
      unresolvedFaces: unresolvedFaces ?? this.unresolvedFaces,
      finalPresentStudents: finalPresentStudents ?? this.finalPresentStudents,
      finalAbsentStudents: finalAbsentStudents ?? this.finalAbsentStudents,
      manualEdits: manualEdits ?? this.manualEdits,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }
}
