// lib/widgets/connection_status_overlay.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/core/connection_state_manager.dart' as csm;

class ConnectionStatusOverlay extends StatelessWidget {
  const ConnectionStatusOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<csm.ConnectionStateManager>(
      builder: (context, connectionStateManager, child) {
        if (connectionStateManager.state == csm.ConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: connectionStateManager.state != csm.ConnectionState.connected ? 80 : 0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(connectionStateManager.state),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStatusTitle(connectionStateManager.state),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusMessage(connectionStateManager.state, connectionStateManager.errorMessage),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (connectionStateManager.state == csm.ConnectionState.disconnected ||
                        connectionStateManager.state == csm.ConnectionState.error)
                      ElevatedButton.icon(
                        onPressed: () => connectionStateManager.retryConnection(),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _getGradientColors(connectionStateManager.state)[1],
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    if (connectionStateManager.state == csm.ConnectionState.connecting)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(csm.ConnectionState state) {
    switch (state) {
      case csm.ConnectionState.connected:
        return [Colors.green.shade400, Colors.green.shade600];
      case csm.ConnectionState.disconnected:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case csm.ConnectionState.connecting:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case csm.ConnectionState.error:
        return [Colors.red.shade400, Colors.red.shade600];
    }
  }

  String _getStatusTitle(csm.ConnectionState state) {
    switch (state) {
      case csm.ConnectionState.connected:
        return 'Connected';
      case csm.ConnectionState.disconnected:
        return 'Disconnected';
      case csm.ConnectionState.connecting:
        return 'Connecting';
      case csm.ConnectionState.error:
        return 'Connection Error';
    }
  }

  String _getStatusMessage(csm.ConnectionState state, String errorMessage) {
    switch (state) {
      case csm.ConnectionState.connected:
        return 'Your connection is stable';
      case csm.ConnectionState.disconnected:
        return 'Please check your network settings';
      case csm.ConnectionState.connecting:
        return 'Establishing connection...';
      case csm.ConnectionState.error:
        return errorMessage.isNotEmpty ? errorMessage : 'An unexpected error occurred';
    }
  }
}