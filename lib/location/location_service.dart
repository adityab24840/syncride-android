import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Continuous GPS while the app is backgrounded, via a foreground service
/// (required on Android for reliable nav-grade location updates).
class LocationService {
  static Future<bool> ensurePermissions() async {
    var status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return false;
    status = await Permission.locationAlways.request();
    await Permission.notification.request();
    return true;
  }

  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'syncride_location',
        channelName: 'SyncRide location sharing',
        channelDescription: 'Shares your live location with your trip group.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'SyncRide is sharing your location',
      notificationText: 'Tap to return to your trip',
      callback: _startLocationCallback,
    );
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  /// Position updates relayed from the foreground task isolate.
  Stream<Position> get positionStream {
    final controller = StreamController<Position>.broadcast();
    void callback(Object data) {
      if (data is Map && data['type'] == 'position') {
        controller.add(Position.fromMap(Map<String, dynamic>.from(data['value'])));
      }
    }

    FlutterForegroundTask.addTaskDataCallback(callback);
    controller.onCancel = () => FlutterForegroundTask.removeTaskDataCallback(callback);
    return controller.stream;
  }
}

@pragma('vm:entry-point')
void _startLocationCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationTaskHandler());
}

class _LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'position',
        'value': position.toJson(),
      });
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _sub?.cancel();
  }
}
