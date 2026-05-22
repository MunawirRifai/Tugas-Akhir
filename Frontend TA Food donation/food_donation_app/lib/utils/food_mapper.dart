import 'api_config.dart';

class FoodRecord {
  final Map<String, dynamic> data;

  const FoodRecord(this.data);

  int? get id => FoodMapper.intOf(
        FoodMapper.valueOf(data, ['id', 'food_id', 'foodId']),
      );

  String get name => FoodMapper.textOf(
        FoodMapper.valueOf(data, ['food_name', 'foodName', 'name', 'title']),
        fallback: 'Makanan',
      );

  String get description => FoodMapper.textOf(
        FoodMapper.valueOf(data, ['description', 'desc', 'note']),
        fallback: 'Tidak ada deskripsi.',
      );

  String get address => FoodMapper.textOf(
        FoodMapper.valueOf(data, ['address', 'location', 'pickup_address']),
        fallback: 'Lokasi belum tersedia.',
      );

  int get quantity =>
      FoodMapper.intOf(FoodMapper.valueOf(data, ['quantity', 'qty', 'stock'])) ??
      0;

  double? get latitude => FoodMapper.doubleOf(
        FoodMapper.valueOf(data, ['latitude', 'lat']),
      );

  double? get longitude => FoodMapper.doubleOf(
        FoodMapper.valueOf(data, ['longitude', 'lng', 'lon']),
      );

  String get status => FoodMapper.textOf(
        FoodMapper.valueOf(data, ['status', 'state']),
        fallback: 'POSTED',
      ).toUpperCase();

  String get statusLabel => FoodMapper.statusLabel(status);

  DateTime? get expiredAt => FoodMapper.dateTimeOf(
        FoodMapper.valueOf(data, ['expired_at', 'expiredAt', 'expires_at']),
      );

  String get expiredAtLabel => FoodMapper.dateTimeLabel(
        expiredAt,
        fallback: FoodMapper.textOf(
          FoodMapper.valueOf(data, ['expired_at', 'expiredAt', 'expires_at']),
          fallback: '-',
        ),
      );

  String? get photoUrl => FoodMapper.resolvePhotoUrl(
        FoodMapper.valueOf(
          data,
          ['photo_url', 'photoUrl', 'image_url', 'imageUrl', 'photo', 'image'],
        ),
      );

  bool get hasLocation => latitude != null && longitude != null;

  bool get isEditable {
    return status == 'POSTED' || status == 'AVAILABLE' || status == 'CANCELED';
  }

  bool get isDeleteAllowed {
    return status != 'ON_THE_WAY' && status != 'PICKED_UP';
  }

  String get coordinateLabel {
    if (!hasLocation) return '-';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(data);
  }
}

class FoodMapper {
  const FoodMapper._();

  static Object? valueOf(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  static String textOf(Object? value, {required String fallback}) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  static int? intOf(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double? doubleOf(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static DateTime? dateTimeOf(Object? value) {
    final String raw = value?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return null;
    }

    return DateTime.tryParse(raw)?.toLocal();
  }

  static String dateTimeLabel(DateTime? dateTime, {String fallback = '-'}) {
    if (dateTime == null) return fallback;

    return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'POSTED':
        return 'Tersedia';
      case 'ON_THE_WAY':
        return 'Sedang diambil';
      case 'PICKED_UP':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  static String? resolvePhotoUrl(Object? value) {
    final String raw = value?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return null;
    }

    final Uri? rawUri = Uri.tryParse(raw);

    if (rawUri != null && rawUri.hasScheme) {
      return raw;
    }

    final Uri baseUri = Uri.parse(ApiConfig.baseUrl);
    final String port = baseUri.hasPort ? ':${baseUri.port}' : '';
    final String origin = '${baseUri.scheme}://${baseUri.host}$port';
    final String normalizedPath = raw.startsWith('/') ? raw : '/$raw';

    return '$origin$normalizedPath';
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

  static List<FoodRecord> recordsFrom(Object? value) {
    if (value is List) {
      return value
          .map(mapOf)
          .where((food) => food.isNotEmpty)
          .map(FoodRecord.new)
          .toList();
    }

    if (value is Map) {
      final Map<String, dynamic> map = mapOf(value);

      final Object? data = map['data'];
      if (data is List) {
        return recordsFrom(data);
      }

      final Object? foods = map['foods'];
      if (foods is List) {
        return recordsFrom(foods);
      }

      if (map.isNotEmpty) {
        return [FoodRecord(map)];
      }
    }

    return [];
  }

  static List<FoodRecord> recordsFromHistory(
    Map<String, dynamic> history,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final Object? value = history[key];

      if (value is List) {
        return recordsFrom(value);
      }

      if (value is Map && value['data'] is List) {
        return recordsFrom(value['data']);
      }
    }

    final Object? nestedData = history['data'];

    if (nestedData is Map) {
      final Map<String, dynamic> nestedHistory = mapOf(nestedData);
      return recordsFromHistory(nestedHistory, keys);
    }

    return [];
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}