import 'package:flutter/material.dart';

import '../realtime/trip_repository.dart';
import 'trip_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = TripRepository();
  final _joinCodeController = TextEditingController();
  bool _loading = false;

  Future<void> _createTrip() async {
    setState(() => _loading = true);
    try {
      final trip = await _repo.createTrip();
      _openTrip(trip.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinTrip() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _repo.getTrip(code);
      _openTrip(code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTrip(String code) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripMapScreen(tripCode: code)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SyncRide')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: _loading ? null : _createTrip,
              child: const Text('Create trip'),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _joinCodeController,
              decoration: const InputDecoration(labelText: 'Trip code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : _joinTrip,
              child: const Text('Join trip'),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => _openTrip('PREVIEW'),
              child: const Text('Preview map (no backend)'),
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
