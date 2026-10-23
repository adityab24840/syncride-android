import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../location/location_service.dart';
import '../maps/directions_service.dart';
import '../maps/navigation_launcher.dart';
import '../realtime/socket_manager.dart';
import '../sos/sos_manager.dart';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key, required this.tripCode});

  final String tripCode;

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  final _socket = SocketManager();
  final _locationService = LocationService();
  final _directions = DirectionsService();
  final _mapController = MapController();
  late final SosManager _sos;

  final Map<String, LatLng> _riderPositions = {};
  List<LatLng> _routePoints = [];
  LatLng? _ownPosition;

  @override
  void initState() {
    super.initState();
    _sos = SosManager(_socket);
    _init();
  }

  Future<void> _init() async {
    final granted = await LocationService.ensurePermissions();
    if (!granted) return;

    _socket.connect();
    _socket.joinTrip(widget.tripCode);
    _socket.onRiderLocation(_onRiderLocation);
    _sos.onSosReceived(_onSosReceived);

    await _locationService.start();
    _locationService.positionStream.listen(_onOwnPosition);
  }

  void _onOwnPosition(Position position) {
    final here = LatLng(position.latitude, position.longitude);
    _socket.sendLocation(position.latitude, position.longitude);
    setState(() => _ownPosition = here);
    _mapController.move(here, _mapController.camera.zoom);
  }

  void _onRiderLocation(Map<String, dynamic> data) {
    final id = data['riderId'] as String? ?? 'rider';
    final lat = (data['lat'] as num).toDouble();
    final lon = (data['lon'] as num).toDouble();
    setState(() => _riderPositions[id] = LatLng(lat, lon));
  }

  void _onSosReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SOS'),
        content: Text('${data['riderId'] ?? 'A rider'} triggered SOS.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showRoute(LatLng destination) async {
    final origin = _ownPosition ?? _riderPositions.values.firstOrNull ?? destination;
    final points = await _directions.getRoutePolyline(origin: origin, destination: destination);
    setState(() => _routePoints = points);
  }

  @override
  void dispose() {
    _locationService.stop();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip ${widget.tripCode}')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(0, 0),
          initialZoom: 14,
          onLongPress: (_, point) => _showRoute(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.syncride.syncride',
          ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(points: _routePoints, strokeWidth: 5, color: Colors.blue),
            ]),
          MarkerLayer(markers: [
            if (_ownPosition != null)
              Marker(
                point: _ownPosition!,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            for (final entry in _riderPositions.entries)
              Marker(
                point: entry.value,
                child: const Icon(Icons.location_on, color: Colors.red),
              ),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        onPressed: _sos.trigger,
        icon: const Icon(Icons.warning),
        label: const Text('SOS'),
      ),
      bottomNavigationBar: _routePoints.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () {
                    final dest = _routePoints.last;
                    NavigationLauncher.launchTurnByTurn(
                      destLat: dest.latitude,
                      destLon: dest.longitude,
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start turn-by-turn'),
                ),
              ),
            ),
    );
  }
}
