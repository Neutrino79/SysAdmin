import 'package:flutter/material.dart';
import '../services/ssh_manager.dart';
import '../services/connection_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _commandController = TextEditingController();
  final SSHManager _sshManager = SSHManager.getInstance();
  final ConnectionManager _connectionManager = ConnectionManager.getInstance();

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (!_sshManager.isConnected()) {
      final connected = await _sshManager.connectWithSavedCredentials();
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect. Please try again.')),
        );
        _navigateToRegisterPage();
      }
    }
  }

  void _navigateToRegisterPage() {
    Navigator.of(context).pushReplacementNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(labelText: 'Enter command'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _executeCommand,
              child: const Text('Execute Command'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _terminateConnection,
              child: const Text('Terminate Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeCommand() async {
    try {
      final result = await _sshManager.executeCommand(_commandController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? 'No result')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error executing command: $e')),
      );
    }
  }

  Future<void> _terminateConnection() async {
    try {
      _sshManager.disconnectFromServer();
      await _connectionManager.deactivateCurrentConnection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection terminated')),
      );
      _navigateToRegisterPage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error terminating connection: $e')),
      );
    }
  }
}