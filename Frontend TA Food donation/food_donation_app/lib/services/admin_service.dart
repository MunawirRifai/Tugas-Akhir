import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class AdminService {
  static String get baseUrl => '${ApiConfig.baseUrl}/admin';

  static Future<Map<String, dynamic>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> banUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/ban'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> timeoutUser(
      String token, int userId, int hours) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/timeout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'hours': hours}),
    );

    return jsonDecode(response.body);
  }
}
