import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8080/api/v1';
    } else {
      // 10.0.2.2 is the special alias to your host loopback interface in Android emulator
      // If testing on a physical device, change this to your laptop's IP address (e.g., 192.168.1.x)
      return 'http://10.0.2.2:8080/api/v1';
    }
  }
}
