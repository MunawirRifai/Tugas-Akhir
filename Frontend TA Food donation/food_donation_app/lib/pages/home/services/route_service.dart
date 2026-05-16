import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static Future<List<LatLng>> getRoute({
    required LatLng currentLocation,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${currentLocation.longitude},${currentLocation.latitude};'
      '$longitude,$latitude?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);

    final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

    return coordinates
        .map(
          (point) => LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          ),
        )
        .toList();
  }
}