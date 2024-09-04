// lib/services/connection_state_manager.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'connection_manager.dart';
import 'ssh_manager.dart';

enum ConnectionState {
  connected,
  disconnected,
  connecting,
  error,
}

class ConnectionStateManager extends ChangeNotifier {
  static final ConnectionStateManager _instance = ConnectionStateManager._internal();
  factory ConnectionStateManager() => _instance;

  ConnectionStateManager._internal() {
    _initConnectivity();
  }

  final ConnectionManager _connectionManager = ConnectionManager.getInstance();
  final SSHManager _sshManager = SSHManager.getInstance();
  final Connectivity _connectivity = Connectivity();

  ConnectionState _state = ConnectionState.disconnected;
  String _errorMessage = '';
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectionState get state => _state;
  String get errorMessage => _errorMessage;

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionState);
  }

  Future<void> _updateConnectionState(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _state = ConnectionState.disconnected;
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }

    _state = ConnectionState.connecting;
    notifyListeners();

    try {
      final activeConnection = await _connectionManager.getActiveConnection();
      if (activeConnection == null) {
        _state = ConnectionState.disconnected;
        _errorMessage = 'No active connection';
      } else {
        final connected = await _sshManager.connectToServer(activeConnection);
        if (connected) {
          _state = ConnectionState.connected;
          _errorMessage = '';
        } else {
          _state = ConnectionState.error;
          _errorMessage = 'Failed to connect to the server';
        }
      }
    } catch (e) {
      _state = ConnectionState.error;
      _errorMessage = 'An error occurred: $e';
    }

    notifyListeners();
  }

  Future<void> retryConnection() async {
    await _updateConnectionState(await _connectivity.checkConnectivity());
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}