import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String fullName;
  final String rollNumber;
  final String classId;
  final List<String> enrollmentImages;
  final List<List<double>> faceEmbeddings;
  final DateTime createdAt;

  StudentModel({
    required this.studentId,
    required this.fullName,
    required this.rollNumber,
    required this.classId,
    this.enrollmentImages = const [],
    this.faceEmbeddings = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    List<List<double>> embeddings = [];
    if (map['faceEmbeddings'] != null) {
      for (var embedding in map['faceEmbeddings']) {
        if (embedding is String) {
          embeddings.add(List<double>.from(jsonDecode(embedding)));
        } else if (embedding is List) {
          embeddings.add(List<double>.from(embedding));
        }
      }
    }

    // Parse createdAt: may be a Firestore Timestamp (app) or ISO string (web registration)
    DateTime parsedCreatedAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return StudentModel(
      studentId: id,
      // 'name' is used by the web registration backend; 'fullName' by the Flutter app
      fullName: map['fullName'] ?? map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      classId: map['classId'] ?? '',
      enrollmentImages: List<String>.from(map['enrollmentImages'] ?? []),
      faceEmbeddings: embeddings,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'rollNumber': rollNumber,
      'classId': classId,
      'enrollmentImages': enrollmentImages,
      'faceEmbeddings': faceEmbeddings.map((e) => jsonEncode(e)).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  StudentModel copyWith({
    String? studentId,
    String? fullName,
    String? rollNumber,
    String? classId,
    List<String>? enrollmentImages,
    List<List<double>>? faceEmbeddings,
    DateTime? createdAt,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      rollNumber: rollNumber ?? this.rollNumber,
      classId: classId ?? this.classId,
      enrollmentImages: enrollmentImages ?? this.enrollmentImages,
      faceEmbeddings: faceEmbeddings ?? this.faceEmbeddings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
