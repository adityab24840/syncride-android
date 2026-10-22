import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  late final SosManager _sos;

  final Map<String, Marker> _riderMarkers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

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
    _socket.sendLocation(position.latitude, position.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  void _onRiderLocation(Map<String, dynamic> data) {
    final id = data['riderId'] as String? ?? 'rider';
    final lat = (data['lat'] as num).toDouble();
    final lon = (data['lon'] as num).toDouble();
    setState(() {
      _riderMarkers[id] = Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(title: id),
      );
    });
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
    final origin = _riderMarkers.values.isNotEmpty
        ? _riderMarkers.values.first.position
        : destination;
    final points = await _directions.getRoutePolyline(origin: origin, destination: destination);
    setState(() {
      _polylines = {
        Polyline(polylineId: const PolylineId('route'), points: points, width: 5),
      };
    });
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
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 14),
        onMapCreated: (c) => _mapController = c,
        markers: _riderMarkers.values.toSet(),
        polylines: _polylines,
        myLocationEnabled: true,
        onLongPress: _showRoute,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        onPressed: _sos.trigger,
        icon: const Icon(Icons.warning),
        label: const Text('SOS'),
      ),
      bottomNavigationBar: _polylines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () {
                    final dest = _polylines.first.points.last;
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
