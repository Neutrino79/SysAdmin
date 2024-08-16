// lib/services/connection_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SSHConnection {
  final String name;
  final String hostId;
  final String username;
  final String privateKeyContent;
  bool isActive;

  SSHConnection({
    required this.name,
    required this.hostId,
    required this.username,
    required this.privateKeyContent,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hostId': hostId,
      'username': username,
      'privateKeyContent': privateKeyContent,
      'isActive': isActive,
    };
  }

  factory SSHConnection.fromMap(Map<String, dynamic> map) {
    return SSHConnection(
      name: map['name'],
      hostId: map['hostId'],
      username: map['username'],
      privateKeyContent: map['privateKeyContent'],
      isActive: map['isActive'] ?? false,
    );
  }
}

class ConnectionManager {
  static const String _storageKey = 'ssh_connections';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static ConnectionManager? _instance;

  ConnectionManager._();

  static ConnectionManager getInstance() {
    _instance ??= ConnectionManager._();
    return _instance!;
  }

  Future<void> addConnection(SSHConnection connection) async {
    final connections = await _getConnections();
    connections.add(connection);
    await _saveConnections(connections);
  }

  Future<List<SSHConnection>> getConnections() async {
    return await _getConnections();
  }


  Future<String> getInitialRoute() async {
    final connections = await getConnections();
    if (connections.isEmpty) {
      return '/welcome';
    } else if (connections.any((conn) => conn.isActive)) {
      return '/home';
    } else {
      return '/register';
    }
  }

  Future<void> setActiveConnection(String name) async {
    final connections = await getConnections();
    for (var conn in connections) {
      conn.isActive = (conn.name == name);
    }
    await _saveConnections(connections);
  }



  Future<List<Map<String, String>>> getConnectionSummaries() async {
    final connections = await _getConnections();
    return connections.map((conn) => {
      'name': conn.name,
      'hostId': conn.hostId,
      'username': conn.username,
    }).toList();
  }

  Future<void> updateConnection(SSHConnection updatedConnection) async {
    final connections = await _getConnections();
    final index = connections.indexWhere((conn) => conn.name == updatedConnection.name);
    if (index != -1) {
      connections[index] = updatedConnection;
      await _saveConnections(connections);
    }
  }

  Future<void> deleteConnection(String name) async {
    final connections = await _getConnections();
    connections.removeWhere((conn) => conn.name == name);
    await _saveConnections(connections);
  }

  Future<SSHConnection?> getActiveConnection() async {
    final connections = await _getConnections();
    try {
      return connections.firstWhere((conn) => conn.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasActiveConnection() async {
    final connections = await _getConnections();
    return connections.any((conn) => conn.isActive);
  }

  Future<List<SSHConnection>> _getConnections() async {
    final String? jsonString = await _secureStorage.read(key: _storageKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => SSHConnection.fromMap(json)).toList();
  }

  Future<void> _saveConnections(List<SSHConnection> connections) async {
    final jsonString = json.encode(connections.map((conn) => conn.toMap()).toList());
    await _secureStorage.write(key: _storageKey, value: jsonString);
  }

  Future<bool> isHostIdExists(String hostId) async {
    final connections = await _getConnections();
    return connections.any((conn) => conn.hostId == hostId);
  }
}