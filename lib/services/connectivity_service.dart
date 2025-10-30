import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _connectivityTimer;

  void startMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkConnectivity(),
    );
    checkConnectivity();
  }

  void stopMonitoring() {
    _connectivityTimer?.cancel();
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));

      _isOnline = response.statusCode == 200;
      _connectivityController.add(_isOnline);

      debugPrint('[Connectivity] Status: ${_isOnline ? "Online" : "Offline"}');
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      _connectivityController.add(_isOnline);
      debugPrint('[Connectivity] Status: Offline (error: $e)');
      return false;
    }
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
