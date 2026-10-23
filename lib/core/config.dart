import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get apiBaseUrl =>
      dotenv.env['SYNCRIDE_API_BASE_URL'] ?? 'http://10.0.2.2:4000';

  static String get osrmBaseUrl =>
      dotenv.env['OSRM_BASE_URL'] ?? 'https://router.project-osrm.org';
}
