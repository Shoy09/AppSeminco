// lib/services/ConnectivityService.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityServiceMina2 with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = false;
  Completer<void> _initCompleter = Completer<void>();
  
  bool get isConnected => _isConnected;
  Future<void> get initialized => _initCompleter.future;
  
  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged
    .map((result) => result != ConnectivityResult.none);


  ConnectivityServiceMina2() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Check initial status
      _isConnected = await _checkInitialConnection();
      _printConnectionStatus();
      
      // Listen for changes
      _connectivity.onConnectivityChanged.listen((result) {
        _updateConnectionStatus(result);
      });
      
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Future<bool> _checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

bool _updateConnectionStatus(ConnectivityResult result) {
  final newStatus = result != ConnectivityResult.none;
  if (newStatus != _isConnected) {
    _isConnected = newStatus;
    _printConnectionStatus();
    notifyListeners();
    return true;
  }
  return false;
}

  void _printConnectionStatus() {
    if (_isConnected) {
      print('✅ Estamos conectados a internet desde service mina 2');
    } else {
      print('❌ No hay conexión a internet desde service mina 2');
    }
  }
}