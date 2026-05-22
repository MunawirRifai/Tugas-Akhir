import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/api_config.dart';

class AuthService {
  const AuthService._();

  static const Duration _timeout = Duration(seconds: 20);

  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'phone': phone.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> verifyRegister({
    required String verificationToken,
    required String code,
  }) {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/verify-register'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'verificationToken': verificationToken,
          'code': code.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _send(
      () => http.post(
        Uri.parse('$baseUrl/login'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getProfile(String token) {
    return _send(
      () => http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    required String phone,
  }) {
    return _send(
      () => http.put(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required XFile image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/me/photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: image.name,
        ),
      );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload profile photo: ${response.statusCode}');
      debugPrint(response.body);

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout. Coba lagi beberapa saat.');
    } catch (error) {
      return _failure('Tidak dapat mengunggah foto profil: $error');
    }
  }

  static String? extractAccessToken(Map<String, dynamic> response) {
    final data = response['data'];

    final candidates = <Object?>[
      if (data is Map) data['access_token'],
      if (data is Map) data['accessToken'],
      if (data is Map) data['token'],
      response['access_token'],
      response['accessToken'],
      response['token'],
    ];

    for (final candidate in candidates) {
      final token = candidate?.toString().trim();
      if (token != null && token.isNotEmpty && token != 'null') {
        return token;
      }
    }

    return null;
  }

  static String? extractVerificationToken(Map<String, dynamic> response) {
    final data = response['data'];

    final candidates = <Object?>[
      if (data is Map) data['verification_token'],
      if (data is Map) data['verificationToken'],
      if (data is Map) data['token'],
      response['verification_token'],
      response['verificationToken'],
      response['token'],
    ];

    for (final candidate in candidates) {
      final token = candidate?.toString().trim();
      if (token != null && token.isNotEmpty && token != 'null') {
        return token;
      }
    }

    return null;
  }

  static String messageOf(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message']?.toString().trim();

    if (message != null && message.isNotEmpty && message != 'null') {
      return message;
    }

    return fallback;
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(_timeout);
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
    final body = _decodeJsonMap(response.body);
    final isSuccessStatus = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccessStatus) {
      if (body.containsKey('success')) {
        return body;
      }

      return {
        'success': true,
        'data': body,
        'statusCode': response.statusCode,
      };
    }

    return {
      ...body,
      'success': false,
      'statusCode': response.statusCode,
      'message': body['message']?.toString() ??
          'Server error (${response.statusCode}).',
    };
  }

  static Map<String, dynamic> _decodeJsonMap(String rawBody) {
    final body = rawBody.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);

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

  static Map<String, dynamic> _failure(String message) {
    return {
      'success': false,
      'message': message,
    };
  }
}