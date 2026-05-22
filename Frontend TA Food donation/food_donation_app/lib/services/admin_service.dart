import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class AdminService {
  const AdminService._();

  static const Duration _timeout = Duration(seconds: 25);

  static String get baseUrl => '${ApiConfig.baseUrl}/admin';

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getDashboard(String token) async {
    final Map<String, dynamic> dashboardResponse = await _send(
      () => http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: _headers(token),
      ),
    );

    if (dashboardResponse['success'] == true) {
      return dashboardResponse;
    }

    final List<Map<String, dynamic>> users = await _safeLoadUsers(token);
    final List<Map<String, dynamic>> foods = await _safeLoadFoods(token);

    return {
      'success': true,
      'message': 'Dashboard fallback generated from users and foods.',
      'data': {
        'users': users,
        'foods': foods,
        'stats': {
          'totalUsers': users.length,
          'totalFoods': foods.length,
          'totalDonations': foods.length,
          'totalClaims': foods
              .where(
                (food) => _statusOf(food) == 'ON_THE_WAY' ||
                    _statusOf(food) == 'PICKED_UP',
              )
              .length,
        },
      },
    };
  }

  static Future<Map<String, dynamic>> getDashboardData(String token) {
    return getDashboard(token);
  }

  static Future<Map<String, dynamic>> getStats(String token) {
    return getDashboard(token);
  }

  static Future<List<Map<String, dynamic>>> getUsers(String token) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat data user.',
      );
    }

    return listOf(
      _firstAvailableValue(
        response,
        [
          'users',
          'data',
          'items',
        ],
      ),
    );
  }

  static Future<List<dynamic>> getAllUsers(String token) async {
    return getUsers(token);
  }

  static Future<List<Map<String, dynamic>>> getFoods(String token) async {
    final Map<String, dynamic> adminResponse = await _send(
      () => http.get(
        Uri.parse('$baseUrl/foods'),
        headers: _headers(token),
      ),
    );

    if (adminResponse['success'] == true) {
      return listOf(
        _firstAvailableValue(
          adminResponse,
          [
            'foods',
            'data',
            'items',
          ],
        ),
      );
    }

    final Map<String, dynamic> publicFoodsResponse = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/foods'),
        headers: _headers(token),
      ),
    );

    if (publicFoodsResponse['success'] == false) {
      throw Exception(
        publicFoodsResponse['message']?.toString() ??
            adminResponse['message']?.toString() ??
            'Gagal memuat data makanan.',
      );
    }

    return listOf(
      _firstAvailableValue(
        publicFoodsResponse,
        [
          'foods',
          'data',
          'items',
        ],
      ),
    );
  }

  static Future<List<dynamic>> getAllFoods(String token) async {
    return getFoods(token);
  }

  static Future<void> deleteFood({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> adminResponse = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/foods/$foodId'),
        headers: _headers(token),
      ),
    );

    if (adminResponse['success'] == true) {
      return;
    }

    final Map<String, dynamic> publicResponse = await _send(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/foods/$foodId'),
        headers: _headers(token),
      ),
    );

    if (publicResponse['success'] == false) {
      throw Exception(
        publicResponse['message']?.toString() ??
            adminResponse['message']?.toString() ??
            'Gagal menghapus makanan.',
      );
    }
  }

  static Future<void> deleteUser({
    required String token,
    required int userId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal menghapus user.',
      );
    }
  }

  static Future<void> blockUser({
    required String token,
    required int userId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/users/$userId/block'),
        headers: _headers(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memblokir user.',
      );
    }
  }

  static Future<void> unblockUser({
    required String token,
    required int userId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/users/$userId/unblock'),
        headers: _headers(token),
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal membuka blokir user.',
      );
    }
  }

  static String messageOf(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final String message = response['message']?.toString().trim() ?? '';

    if (message.isNotEmpty && message != 'null') {
      return message;
    }

    return fallback;
  }

  static Map<String, dynamic> mapOf(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> listOf(Object? value) {
    if (value is List) {
      return value
          .map(mapOf)
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is Map) {
      final Map<String, dynamic> map = mapOf(value);

      for (final String key in ['data', 'items', 'users', 'foods']) {
        final Object? nestedValue = map[key];

        if (nestedValue is List) {
          return listOf(nestedValue);
        }
      }

      if (map.isNotEmpty) {
        return [map];
      }
    }

    return [];
  }

  static int? intOf(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static String textOf(Object? value, {required String fallback}) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  static String dateLabel(Object? value) {
    final String raw = value?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return '-';
    }

    final DateTime? dateTime = DateTime.tryParse(raw)?.toLocal();

    if (dateTime == null) {
      return raw;
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(_timeout);

      debugPrint('ADMIN SERVICE STATUS: ${response.statusCode}');
      debugPrint('ADMIN SERVICE BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout. Periksa jaringan lalu coba lagi.');
    } on FormatException {
      return _failure('Format respons server tidak valid.');
    } catch (error) {
      return _failure('Tidak dapat terhubung ke backend: $error');
    }
  }

  static Map<String, dynamic> _normalizeResponse(http.Response response) {
    final Map<String, dynamic> body = _decodeJsonMap(response.body);
    final bool isSuccessStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    final Map<String, dynamic> normalized = {
      ...body,
      'statusCode': response.statusCode,
    };

    normalized.putIfAbsent('success', () => isSuccessStatus);

    if (isSuccessStatus) {
      normalized.putIfAbsent('message', () => 'OK');
      return normalized;
    }

    normalized['success'] = false;
    normalized.putIfAbsent(
      'message',
      () => 'Server error (${response.statusCode}).',
    );

    return normalized;
  }

  static Map<String, dynamic> _decodeJsonMap(String rawBody) {
    final String body = rawBody.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {
      'data': decoded,
    };
  }

  static Object? _firstAvailableValue(
    Map<String, dynamic> response,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final Object? value = response[key];

      if (value is List) {
        return value;
      }

      if (value is Map) {
        final Map<String, dynamic> mappedValue = mapOf(value);

        for (final String nestedKey in keys) {
          final Object? nestedValue = mappedValue[nestedKey];

          if (nestedValue is List) {
            return nestedValue;
          }
        }

        if (key == 'data') {
          return value;
        }
      }
    }

    return response['data'];
  }

  static Future<List<Map<String, dynamic>>> _safeLoadUsers(
    String token,
  ) async {
    try {
      return await getUsers(token);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _safeLoadFoods(
    String token,
  ) async {
    try {
      return await getFoods(token);
    } catch (_) {
      return [];
    }
  }

  static String _statusOf(Map<String, dynamic> food) {
    return textOf(
      food['status'],
      fallback: 'POSTED',
    ).toUpperCase();
  }

  static Map<String, dynamic> _failure(String message) {
    return {
      'success': false,
      'message': message,
    };
  }
}