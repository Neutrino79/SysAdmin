import 'package:flutter/material.dart';
import '../services/core/connection_manager.dart';
import '../services/core/connection_state_manager.dart' as csm;
import '../widgets/home_page/connection-status-card.dart';

class ConnectionStatusPill extends StatelessWidget {
  final SSHConnection? connection;
  final csm.ConnectionState connectionState;

  const ConnectionStatusPill({
    Key? key,
    required this.connection,
    required this.connectionState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showStatusDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(colorScheme),
            const SizedBox(width: 8),
            Text(
              connection?.username ?? 'Not Connected',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (connectionState) {
      case csm.ConnectionState.connected:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case csm.ConnectionState.disconnected:
        iconData = Icons.cancel;
        iconColor = Colors.orange;
        break;
      case csm.ConnectionState.connecting:
        iconData = Icons.sync;
        iconColor = Colors.blue;
        break;
      case csm.ConnectionState.error:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
    }

    return Icon(iconData, color: iconColor, size: 16);
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connection Info'),
          content: SingleChildScrollView(
            child: ConnectionStatusCard(
              connection: connection,
              connectionState: connectionState,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}