import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/config.dart';

/// Thin wrapper over the existing SyncRide backend's Socket.IO contract.
/// Event names/payloads match apps/api exactly — only the client changed.
class SocketManager {
  late final io.Socket _socket;

  void connect() {
    _socket = io.io(
      Config.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
  }

  void joinTrip(String tripCode) {
    _socket.emit('trip:join', {'code': tripCode});
  }

  void sendLocation(double lat, double lon) {
    _socket.emit('location:update', {'lat': lat, 'lon': lon});
  }

  void onRiderLocation(void Function(Map<String, dynamic> data) callback) {
    _socket.on('location:broadcast', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void sendSos() => _socket.emit('sos:send');

  void onSos(void Function(Map<String, dynamic> data) callback) {
    _socket.on('sos:broadcast', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void dispose() {
    _socket.dispose();
  }
}
