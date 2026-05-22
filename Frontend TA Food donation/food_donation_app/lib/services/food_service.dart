import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/api_config.dart';

class ImageOptimizationResult {
  final XFile source;
  final Uint8List bytes;
  final String fileName;
  final int originalBytes;
  final int estimatedUploadBytes;
  final double estimatedQuality;
  final bool isSimulation;

  const ImageOptimizationResult({
    required this.source,
    required this.bytes,
    required this.fileName,
    required this.originalBytes,
    required this.estimatedUploadBytes,
    required this.estimatedQuality,
    required this.isSimulation,
  });

  int get estimatedSavedBytes {
    return math.max(0, originalBytes - estimatedUploadBytes);
  }

  double get estimatedSavedPercent {
    if (originalBytes <= 0) return 0;
    return estimatedSavedBytes / originalBytes * 100;
  }

  String get originalSizeLabel => FoodService.formatBytes(originalBytes);

  String get estimatedUploadSizeLabel {
    return FoodService.formatBytes(estimatedUploadBytes);
  }

  String get estimatedSavedSizeLabel {
    return FoodService.formatBytes(estimatedSavedBytes);
  }
}

class FoodService {
  const FoodService._();

  static const Duration _timeout = Duration(seconds: 25);

  static String get baseUrl => '${ApiConfig.baseUrl}/foods';

  static Future<ImageOptimizationResult> optimizeImageForUpload(
    XFile image,
  ) async {
    final Uint8List bytes = await image.readAsBytes();
    final int originalBytes = bytes.lengthInBytes;

    final int estimatedUploadBytes = _estimateCompressedImageSize(
      originalBytes,
    );

    final double estimatedQuality = _estimateImageQuality(originalBytes);

    return ImageOptimizationResult(
      source: image,
      bytes: bytes,
      fileName: _safeFileName(image.name),
      originalBytes: originalBytes,
      estimatedUploadBytes: estimatedUploadBytes,
      estimatedQuality: estimatedQuality,
      isSimulation: true,
    );
  }

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
    ImageOptimizationResult? optimizedImage,
  }) async {
    try {
      final ImageOptimizationResult optimization =
          optimizedImage ?? await optimizeImageForUpload(image);

      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['foodName'] = foodName.trim();
      request.fields['description'] = description.trim();
      request.fields['quantity'] = quantity.toString();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address.trim();
      request.fields['expiredAt'] = expiredAt;

      request.fields['imageOriginalBytes'] =
          optimization.originalBytes.toString();
      request.fields['imageEstimatedUploadBytes'] =
          optimization.estimatedUploadBytes.toString();
      request.fields['imageEstimatedQuality'] =
          optimization.estimatedQuality.toStringAsFixed(2);
      request.fields['imageOptimizationMode'] = 'simulation';

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          optimization.bytes,
          filename: optimization.fileName,
        ),
      );

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);
      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      debugPrint('CREATE FOOD STATUS: ${response.statusCode}');
      debugPrint('CREATE FOOD BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout saat membuat postingan makanan.');
    } catch (error) {
      return _failure('Tidak dapat membuat postingan makanan: $error');
    }
  }

  static Future<Map<String, dynamic>> updateFood({
    required String token,
    required int foodId,
    required String foodName,
    required String description,
    required int quantity,
    required double latitude,
    required double longitude,
    required String address,
    required String expiredAt,
    XFile? image,
    ImageOptimizationResult? optimizedImage,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/$foodId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['foodName'] = foodName.trim();
      request.fields['description'] = description.trim();
      request.fields['quantity'] = quantity.toString();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address.trim();
      request.fields['expiredAt'] = expiredAt;

      if (image != null) {
        final ImageOptimizationResult optimization =
            optimizedImage ?? await optimizeImageForUpload(image);

        request.fields['imageOriginalBytes'] =
            optimization.originalBytes.toString();
        request.fields['imageEstimatedUploadBytes'] =
            optimization.estimatedUploadBytes.toString();
        request.fields['imageEstimatedQuality'] =
            optimization.estimatedQuality.toStringAsFixed(2);
        request.fields['imageOptimizationMode'] = 'simulation';

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            optimization.bytes,
            filename: optimization.fileName,
          ),
        );
      }

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(_timeout);
      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      debugPrint('UPDATE FOOD STATUS: ${response.statusCode}');
      debugPrint('UPDATE FOOD BODY: ${response.body}');

      return _normalizeResponse(response);
    } on TimeoutException {
      return _failure('Koneksi timeout saat memperbarui postingan.');
    } catch (error) {
      return _failure('Tidak dapat memperbarui postingan: $error');
    }
  }

  static Future<List<dynamic>> getFoods(String token) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat data makanan.',
      );
    }

    final Object? data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map && data['foods'] is List) {
      return data['foods'] as List;
    }

    return [];
  }

  static Future<void> deleteFood({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/$foodId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal menghapus postingan.',
      );
    }
  }

  static Future<Map<String, dynamic>> getHistory(String token) async {
    final Map<String, dynamic> response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal memuat riwayat.',
      );
    }

    final Object? data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return {
      'myDonation': [],
      'myClaim': [],
    };
  }

  static Future<Map<String, dynamic>> pickFood({
    required String token,
    required int foodId,
    required int quantity,
  }) async {
    return _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/pick?quantity=$quantity'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<void> confirmPickup({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal konfirmasi pengambilan.',
      );
    }
  }

  static Future<void> cancelPickup({
    required String token,
    required int foodId,
  }) async {
    final Map<String, dynamic> response = await _send(
      () => http.put(
        Uri.parse('$baseUrl/$foodId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response['success'] == false) {
      throw Exception(
        response['message']?.toString() ?? 'Gagal membatalkan pengambilan.',
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

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const int kb = 1024;
    const int mb = kb * 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }

    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(_timeout);

      debugPrint('FOOD SERVICE STATUS: ${response.statusCode}');
      debugPrint('FOOD SERVICE BODY: ${response.body}');

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
    final bool statusSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    final Map<String, dynamic> normalized = {
      ...body,
      'statusCode': response.statusCode,
    };

    normalized.putIfAbsent('success', () => statusSuccess);

    if (statusSuccess) {
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

  static Map<String, dynamic> _failure(String message) {
    return {
      'success': false,
      'message': message,
    };
  }

  static String _safeFileName(String rawName) {
    final String trimmed = rawName.trim();

    if (trimmed.isEmpty || trimmed == 'null') {
      return 'food_photo.jpg';
    }

    return trimmed.replaceAll(RegExp(r'\s+'), '_');
  }

  static int _estimateCompressedImageSize(int originalBytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (originalBytes <= 350 * kb) {
      return originalBytes;
    }

    if (originalBytes <= 1 * mb) {
      return (originalBytes * 0.72).round();
    }

    if (originalBytes <= 3 * mb) {
      return (originalBytes * 0.55).round();
    }

    return (originalBytes * 0.42).round();
  }

  static double _estimateImageQuality(int originalBytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (originalBytes <= 350 * kb) {
      return 1.00;
    }

    if (originalBytes <= 1 * mb) {
      return 0.82;
    }

    if (originalBytes <= 3 * mb) {
      return 0.72;
    }

    return 0.62;
  }
}