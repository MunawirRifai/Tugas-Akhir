import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/api_config.dart';

class FoodService {
  static String get baseUrl => '${ApiConfig.baseUrl}/foods';

  static Future<Map<String, dynamic>> createFood({
    required String token,
    required String foodName,
    required String description,
    required int quantity,
    required double latitude,
    required double longitude,
    required String address,
    required String expiredAt,
    required XFile image,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(baseUrl));

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['foodName'] = foodName;
    request.fields['description'] = description;
    request.fields['quantity'] = quantity.toString();
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['address'] = address;
    request.fields['expiredAt'] = expiredAt;

    final bytes = await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: image.name),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('CREATE FOOD STATUS: ${response.statusCode}');
    debugPrint('CREATE FOOD BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Create food failed (${response.statusCode}): ${response.body}',
      );
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getFoods(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint('GET FOOD STATUS: ${response.statusCode}');
    debugPrint('GET FOOD BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load foods (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return data['data'] ?? [];
  }

  static Future<void> deleteFood({
    required String token,
    required int foodId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$foodId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete food');
    }
  }

  static Future<Map<String, dynamic>> getHistory(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/history'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  return data['data'];
}

  static Future<Map<String, dynamic>> pickFood({
  required String token,
  required int foodId,
  required int quantity,
}) async {

  final response = await http.put(
    Uri.parse('$baseUrl/$foodId/pick?quantity=$quantity'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  return jsonDecode(response.body);
}

  static Future<void> confirmPickup({
    required String token,
    required int foodId,
  }) async {
    await http.put(
      Uri.parse('$baseUrl/$foodId/confirm'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> cancelPickup({
    required String token,
    required int foodId,
  }) async {
    await http.put(
      Uri.parse('$baseUrl/$foodId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
