import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

class Trip {
  final String code;
  final double? destLat;
  final double? destLon;

  Trip({required this.code, this.destLat, this.destLon});

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        code: json['code'] as String,
        destLat: (json['destLat'] as num?)?.toDouble(),
        destLon: (json['destLon'] as num?)?.toDouble(),
      );
}

/// REST calls against the existing SyncRide backend. No backend changes
/// required — same endpoints the web client already uses.
class TripRepository {
  Uri _uri(String path) => Uri.parse('${Config.apiBaseUrl}$path');

  Future<Trip> createTrip({double? destLat, double? destLon}) async {
    final res = await http.post(
      _uri('/api/trips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'destLat': destLat, 'destLon': destLon}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create trip: ${res.statusCode}');
    }
    return Trip.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Trip> getTrip(String code) async {
    final res = await http.get(_uri('/api/trips/$code'));
    if (res.statusCode != 200) {
      throw Exception('Trip not found: $code');
    }
    return Trip.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
