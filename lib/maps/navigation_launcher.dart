import 'package:url_launcher/url_launcher.dart';

/// No in-app turn-by-turn guidance (Google's Navigation SDK isn't available
/// in Flutter and isn't free). Hand off to whatever nav app is installed —
/// same trip data, zero extra cost.
class NavigationLauncher {
  static Future<void> launchTurnByTurn({
    required double destLat,
    required double destLon,
  }) async {
    final uri = Uri.parse(
      'google.navigation:q=$destLat,$destLon&mode=d',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    final fallback = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destLat,$destLon',
      'travelmode': 'driving',
    });
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
}
