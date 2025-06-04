import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Jika pakai google_maps_flutter
import 'package:latlong2/latlong.dart'; // Jika pakai flutter_map

Future<List<LatLng>> getRoutePolyline({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  String mode = 'driving', // bisa 'walking' atau 'cycling'
}) async {
  final url =
      'https://router.project-osrm.org/route/v1/$mode/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    // Konversi dari List<List<double>> ke List<LatLng>
    return coords
        .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
        .toList();
  } else {
    throw Exception('Failed to load route');
  }
}
