import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8080/api/v1';
    } else {
      return 'http://10.0.2.2:8080/api/v1';
    }
  }
}

// jika mau menggunakan hp tinggal rubah return return 'http://ipaddress_laptop:8080/api/v1'; !!!laptop harus hotspot dari hp yang akan di test!!!

// import 'package:flutter/foundation.dart';

// class ApiConfig {
//   static String get baseUrl {
//     if (kIsWeb) {
//       return 'http://127.0.0.1:8080/api/v1';
//     } else {
//       return 'http://10.92.15.189:8080/api/v1';
//     }
//   }
// }





