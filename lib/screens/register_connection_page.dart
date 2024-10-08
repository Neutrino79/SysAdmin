import 'package:flutter/material.dart';
import '../widgets/add_connection_dialog.dart';
import '../services/core/connection_manager.dart';
import '../services/core/ssh_manager.dart';
import 'custom_scrollable_page.dart';

class RegisterConnectionPage extends StatefulWidget {
  const RegisterConnectionPage({Key? key}) : super(key: key);

  @override
  _RegisterConnectionPageState createState() => _RegisterConnectionPageState();
}

class _RegisterConnectionPageState extends State<RegisterConnectionPage> {
  late Future<List<SSHConnection>> _connectionsFuture;
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectionsFuture = ConnectionManager.getInstance().getConnections();
  }

  void _refreshConnections() {
    setState(() {
      _connectionsFuture = ConnectionManager.getInstance().getConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollablePage(
      title: 'SSH Manager',
      icon: Icons.device_hub,
      showBottomNav: false,
      showDrawer: false,
      showSettings: false,
      selectedIndex: _selectedIndex,
      onBottomNavTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              showAddConnectionDialog(context, _refreshConnections);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Connection Manually'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Implement QR scanning functionality
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Add Using QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Connections',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<SSHConnection>>(
            future: _connectionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No connections found');
              } else {
                return Column(
                  children: snapshot.data!.map((connection) => _buildConnectionCard(connection)).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(SSHConnection connection) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceVariant,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StatefulBuilder(
        builder: (context, setState) {
          return ListTile(
            leading: Icon(Icons.computer, color: colorScheme.secondary),
            title: Text(connection.name),
            subtitle: Text(connection.hostId),
            trailing: _isLoading
                ? CircularProgressIndicator()
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => connection.isActive
                      ? _resumeConnection(connection, setState)
                      : _connectToServer(connection, setState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: connection.isActive
                        ? colorScheme.secondary
                        : colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text(connection.isActive ? 'Resume' : 'Connect'),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showBottomSheet(context, connection),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _connectToServer(SSHConnection connection, void Function(void Function()) setState) async {
    setState(() {
      _isLoading = true;
    });

    final sshManager = SSHManager.getInstance();
    final success = await sshManager.connectToServer(connection);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await ConnectionManager.getInstance().setActiveConnection(connection.name);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed')),
      );
    }
  }

  Future<void> _resumeConnection(SSHConnection connection, void Function(void Function()) setState) async {
    setState(() {
      _isLoading = true;
    });

    final sshManager = SSHManager.getInstance();
    final success = await sshManager.connectWithSavedCredentials();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resume connection')),
      );
    }
  }


  void _showBottomSheet(BuildContext context, SSHConnection connection) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Connection Details',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Name', connection.name),
              const SizedBox(height: 8),
              _buildDetailRow('Username', connection.username),
              const SizedBox(height: 8),
              _buildDetailRow('Host ID', connection.hostId),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _deleteConnection(connection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Delete Connection'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Future<void> _deleteConnection(SSHConnection connection) async {
    await ConnectionManager.getInstance().deleteConnection(connection.name);
    Navigator.pop(context);
    _refreshConnections();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection deleted')),
    );
  }
}