// lib/services/ssh_manager.dart

import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'connection_manager.dart';

class SSHManager {
  static SSHManager? _instance;
  SSHClient? _activeClient;

  SSHManager._();

  static SSHManager getInstance() {
    _instance ??= SSHManager._();
    return _instance!;
  }

  Future<bool> testConnection(SSHConnection connection) async {
    try {
      final socket = await SSHSocket.connect(connection.hostId, 22);
      final client = SSHClient(
        socket,
        username: connection.username,
        identities: SSHKeyPair.fromPem(connection.privateKeyContent),
      );

      await client.authenticated;
      client.close();
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<bool> connectToServer(SSHConnection connection) async {
    try {
      final socket = await SSHSocket.connect(connection.hostId, 22);
      _activeClient = SSHClient(
        socket,
        username: connection.username,
        identities: SSHKeyPair.fromPem(connection.privateKeyContent),
      );

      await _activeClient!.authenticated;
      return true;
    } catch (e) {
      print('Connection failed: $e');
      _activeClient = null;
      return false;
    }
  }

  void disconnectFromServer() {
    _activeClient?.close();
    _activeClient = null;
  }

  Future<String?> executeCommand(String command) async {
    if (_activeClient == null) {
      throw Exception('Not connected to any server. Please connect first.');
    }

    try {
      final result = await _activeClient!.run(command);
      return utf8.decode(result);
    } catch (e) {
      print('Command execution failed: $e');
      return null;
    }
  }

  bool isConnected() {
    return _activeClient != null;
  }

  Future<bool> connectWithSavedCredentials() async {
    try {
      final ConnectionManager connectionManager = ConnectionManager.getInstance();
      final activeConnection = await connectionManager.getActiveConnection();
      if (activeConnection != null) {
        return await connectToServer(activeConnection);
      }
      return false;
    } catch (e) {
      print('Error connecting with saved credentials: $e');
      return false;
    }
  }
}