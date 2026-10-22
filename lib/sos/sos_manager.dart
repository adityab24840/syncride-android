import '../realtime/socket_manager.dart';

class SosManager {
  SosManager(this._socket);

  final SocketManager _socket;

  void trigger() => _socket.sendSos();

  void onSosReceived(void Function(Map<String, dynamic> data) callback) {
    _socket.onSos(callback);
  }
}
