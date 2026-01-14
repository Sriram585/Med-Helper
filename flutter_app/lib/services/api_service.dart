import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class ApiService {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use 127.0.0.1 for Web
  static String get baseUrl {
    if (kIsWeb) {
      print('Using Web URL: http://127.0.0.1:8000');
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  // Auth
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  // Features
  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': symptoms}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> chat(
    String message,
    List<dynamic> history,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'history': history}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> generateDiet(
    String goal,
    String preferences,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate_diet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'goal': goal, 'preferences': preferences}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> generateWorkout(
    String goal,
    String level,
    String equipment,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate_workout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'goal': goal, 'level': level, 'equipment': equipment}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> uploadLabReport(
      List<int> bytes, String filename) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze_report_file'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType(
          'application',
          'pdf',
        ), // Simplification, could be text
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) {
        throw Exception('Response body is null');
      }
      if (decoded is! Map<String, dynamic>) {
        // If it's a list (e.g. diet plan), wrap it in a map
        // But for auth, it must be a map.
        if (decoded is List) {
          return {'data': decoded};
        }
        throw Exception(
            'Expected Map<String, dynamic>, got ${decoded.runtimeType}');
      }
      return decoded;
    } else {
      throw Exception(
        'Failed to load data: ${response.statusCode} ${response.body}',
      );
    }
  }
}
