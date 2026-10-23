import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config.dart';

/// Route polyline via OSRM's public routing API — free, no key, no billing.
/// The public demo server (router.project-osrm.org) is rate-limited and
/// meant for light/personal use; swap OSRM_BASE_URL for a self-hosted
/// instance if usage grows.
class DirectionsService {
  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coords =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    final uri = Uri.parse(
      '${Config.osrmBaseUrl}/route/v1/driving/$coords?overview=full&geometries=polyline',
    );

    final res = await http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 'Ok') {
      throw Exception('OSRM routing error: ${body['code']}');
    }

    final points = body['routes'][0]['geometry'] as String;
    return _decodePolyline(points);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
