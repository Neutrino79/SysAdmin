import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_scrollable_page.dart';
import '../services/connection_manager.dart';
import '../services/ssh_manager.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late Future<SSHConnection?> _activeConnectionFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _activeConnectionFuture = ConnectionManager.getInstance().getActiveConnection();
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
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionStatusCard(activeConnection, colorScheme),
                const SizedBox(height: 24),
                _buildSectionHeading(colorScheme, 'System Resources'),
                const SizedBox(height: 24),
                _buildSystemInfoTiles(colorScheme),
                const SizedBox(height: 24),
                _buildSectionHeading(colorScheme, 'Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(colorScheme),
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

  Widget _buildConnectionStatusCard(SSHConnection? connection, ColorScheme colorScheme) {
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
                        connection != null ? Icons.sync : Icons.sync_disabled,
                        color: connection != null ? Colors.green : Colors.red,
                        size: 28,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              connection != null ? 'Connected' : 'Not Connected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer),
            ),
            if (connection != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Host', connection.hostId, colorScheme),
              const SizedBox(height: 8),
              _buildInfoRow('Username', connection.username, colorScheme),
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

  Widget _buildQuickActionsGrid(ColorScheme colorScheme) {
    final actions = [
      {'icon': Icons.terminal, 'label': 'Terminal'},
      {'icon': Icons.folder, 'label': 'File Manager'},
      {'icon': Icons.memory, 'label': 'System Monitor'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surfaceVariant,
          child: InkWell(
            onTap: () {
              // Implement action functionality
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData, size: 36, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  action['label'] as String,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemInfoTiles(ColorScheme colorScheme) {
    final gradient = LinearGradient(
      colors: [
        colorScheme.secondaryContainer,
        colorScheme.tertiaryContainer,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      children: [
        _buildSystemInfoTile(
          colorScheme,
          'CPU & RAM',
          [
            _buildInfoColumn(colorScheme, 'CPU', 0.25, '4 cores', '1 GHz', '3 GHz', Icons.memory),
            _buildInfoColumn(colorScheme, 'RAM', 0.75, '16 GB', '12 GB', '4 GB', Icons.storage),
          ],
          gradient: gradient,
        ),
        const SizedBox(height: 16),
        _buildSystemInfoTile(
          colorScheme,
          'Storage & Network',
          [
            _buildInfoColumn(colorScheme, 'Disk', 0.6, '2 TB', '1 TB', '1 TB', Icons.disc_full),
            _buildInfoColumn(colorScheme, 'Network', 0.4, '100 Mbps', '40 Mbps', '60 Mbps', Icons.network_check),
          ],
          gradient: gradient,
        ),
      ],
    );
  }

  Widget _buildSystemInfoTile(ColorScheme colorScheme, String title, List<Widget> children, {required Gradient gradient}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(ColorScheme colorScheme, String label, double progress, String total, String used, String free, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: CircularProgressPainter(
                    progress: progress,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.onSecondaryContainer.withOpacity(0.2),
                  ),
                ),
                Icon(icon, size: 28, color: colorScheme.onSecondaryContainer),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total: $total',
            style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Used: $used | Free: $free',
            style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularProgressPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 10.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}