import 'package:flutter/material.dart';
import '../../../services/ssh_manager.dart';
import 'dart:math' as math;

import '../../services/connection_manager.dart';

class ConnectionStatusCard extends StatefulWidget {
  final SSHConnection? connection;

  const ConnectionStatusCard({Key? key, required this.connection}) : super(key: key);

  @override
  _ConnectionStatusCardState createState() => _ConnectionStatusCardState();
}

class _ConnectionStatusCardState extends State<ConnectionStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connection Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * math.pi,
                      child: Icon(
                        widget.connection != null ? Icons.sync : Icons.sync_disabled,
                        color: widget.connection != null ? Colors.green : Colors.red,
                        size: 28,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.connection != null ? 'Connected' : 'Not Connected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer),
            ),
            if (widget.connection != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Host', widget.connection!.hostId, colorScheme),
              const SizedBox(height: 8),
              _buildInfoRow('Username', widget.connection!.username, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer.withOpacity(0.8)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: colorScheme.onSecondaryContainer),
        ),
      ],
    );
  }
}
