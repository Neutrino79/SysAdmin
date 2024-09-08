import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'dart:async';
import '../../screens/terminal_page.dart';
import 'connection_manager.dart';

class SSHManager {
  static SSHManager? _instance;
  SSHClient? _activeClient;
  SSHSession? _activeSession;
  StreamController<String>? _outputController;
  List<TerminalEntry> _savedTerminalOutput = [];

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
      _activeSession = await _activeClient!.shell();
      _outputController = StreamController<String>.broadcast();

      _activeSession!.stdout.listen((data) {
        _outputController!.add(utf8.decode(data));
      });

      _activeSession!.stderr.listen((data) {
        _outputController!.add(utf8.decode(data));
      });

      return true;
    } catch (e) {
      print('Connection failed: $e');
      _activeClient = null;
      _activeSession = null;
      _outputController = null;
      return false;
    }
  }

  void disconnectFromServer() {
    _activeSession?.close();
    _activeClient?.close();
    _outputController?.close();
    _activeClient = null;
    _activeSession = null;
    _outputController = null;
  }

  void saveTerminalOutput(List<TerminalEntry> output) {
    _savedTerminalOutput = List.from(output);
  }

  List<TerminalEntry> getSavedTerminalOutput() {
    return List.from(_savedTerminalOutput);
  }

  void clearSavedTerminalOutput() {
    _savedTerminalOutput.clear();
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

  Future<void> sendCommand(String command) async {
    if (_activeSession == null) {
      throw Exception('No active session. Please connect first.');
    }
    _activeSession!.write(utf8.encode(command + '\n'));
  }

  Stream<String>? get terminalOutput => _outputController?.stream;

  bool isConnected() {
    return _activeClient != null && _activeSession != null;
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