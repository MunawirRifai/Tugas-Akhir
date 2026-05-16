import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/api_config.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyRegister({
    required String verificationToken,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'verificationToken': verificationToken, 'code': code}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fullName': fullName, 'email': email, 'phone': phone}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required XFile image,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/me/photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: image.name),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(response.statusCode.toString());
    debugPrint(response.body);

    return jsonDecode(response.body);
  }
}
