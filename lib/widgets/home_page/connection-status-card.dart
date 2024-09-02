// lib/widgets/home_page/connection-status-card.dart

import 'package:flutter/material.dart';
import '../../services/connection_manager.dart';
import '../../services/connection_state_manager.dart' as csm;

class ConnectionStatusCard extends StatelessWidget {
  final SSHConnection? connection;
  final csm.ConnectionState connectionState;

  const ConnectionStatusCard({
    Key? key,
    required this.connection,
    required this.connectionState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(colorScheme),
            if (connection != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.computer, 'Host', connection!.hostId),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Username', connection!.username),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildStatusRow(ColorScheme colorScheme) {
    final statusColor = _getStatusColor(colorScheme);
    final statusText = _getStatusText();

    return Row(
      children: [
        Icon(Icons.circle, color: statusColor, size: 12),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (connectionState) {
      case csm.ConnectionState.connected:
        return Colors.green;
      case csm.ConnectionState.disconnected:
        return Colors.orange;
      case csm.ConnectionState.connecting:
        return Colors.blue;
      case csm.ConnectionState.error:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (connectionState) {
      case csm.ConnectionState.connected:
        return 'Connected';
      case csm.ConnectionState.disconnected:
        return 'Disconnected';
      case csm.ConnectionState.connecting:
        return 'Connecting...';
      case csm.ConnectionState.error:
        return 'Connection Error';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}