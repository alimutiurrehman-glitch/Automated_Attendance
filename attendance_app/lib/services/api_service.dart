import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend server URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  /// Process a classroom image for attendance
  /// Sends image + class_id to the Python backend
  /// Returns recognition results
  Future<Map<String, dynamic>> processAttendanceImage({
    required File imageFile,
    required String classId,
    required List<Map<String, dynamic>> enrolledStudents,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/attendance/process');

      final request = http.MultipartRequest('POST', uri);
      request.fields['class_id'] = classId;
      request.fields['enrolled_students'] = jsonEncode(enrolledStudents);

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Generate face embedding from a single face image (for enrollment)
  Future<List<double>> generateEmbedding(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/api/enrollment/generate-embedding');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<double>.from(data['embedding']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Failed to generate embedding');
      }
    } catch (e) {
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
