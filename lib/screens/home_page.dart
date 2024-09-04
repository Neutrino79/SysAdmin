import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'custom_scrollable_page.dart';
import '../services/core/connection_manager.dart';
import '../services/core/connection_state_manager.dart' as csm;
import '../widgets/home_page/connection-status-card.dart';
import '../widgets/home_page/system-info-tile.dart';
import '../widgets/home_page/quick-actions-grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<SSHConnection?> _activeConnectionFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeConnectionFuture = ConnectionManager.getInstance().getActiveConnection();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connectionStateManager = Provider.of<csm.ConnectionStateManager>(context);

    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: FutureBuilder<SSHConnection?>(
        future: _activeConnectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final activeConnection = snapshot.data;
          return CustomScrollablePage(
            title: activeConnection?.name ?? 'Not Connected',
            icon: Icons.computer,
            showBottomNav: true,
            selectedIndex: _selectedIndex,
            onBottomNavTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              // Handle navigation based on the tapped index
            },
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConnectionStatusCard(
                  connection: activeConnection,
                  connectionState: connectionStateManager.state,
                ),
                const SizedBox(height: 24),
                _buildSectionHeading(colorScheme, 'System Resources'),
                const SizedBox(height: 24),
                SystemInfoTile(),
                const SizedBox(height: 24),
                _buildSectionHeading(colorScheme, 'Quick Actions'),
                const SizedBox(height: 16),
                QuickActionsGrid(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeading(ColorScheme colorScheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: colorScheme.primary.withOpacity(0.5),
            thickness: 1,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}