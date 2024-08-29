import 'package:flutter/material.dart';
import 'dart:async';
import 'circular-progress-painter.dart';
import '../../services/system-info-service.dart';

class SystemInfoTile extends StatefulWidget {
  const SystemInfoTile({Key? key}) : super(key: key);

  @override
  _SystemInfoTileState createState() => _SystemInfoTileState();
}

class _SystemInfoTileState extends State<SystemInfoTile> {
  final SystemInfoService _systemInfoService = SystemInfoService();
  late StreamSubscription<SystemInfo> _subscription;
  SystemInfo _currentInfo = SystemInfo.empty();

  @override
  void initState() {
    super.initState();
    _subscription = _systemInfoService.systemInfoStream.listen((info) {
      setState(() {
        _currentInfo = info;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _systemInfoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
        _buildSystemInfoCard(
          colorScheme,
          'CPU & RAM',
          [
            _buildInfoColumn(colorScheme, 'CPU', _currentInfo.cpuUsage / 100, '${_currentInfo.cpuCores} cores', '${_currentInfo.cpuUsage.toStringAsFixed(1)}%', Icons.memory,remainingText: "Usage"),
            _buildInfoColumn(colorScheme, 'RAM', _currentInfo.ramUsage / 100, '${_currentInfo.totalRam.toStringAsFixed(1)} GB', '${_currentInfo.usedRam.toStringAsFixed(1)} GB', Icons.storage, remainingText: '${_currentInfo.freeRam.toStringAsFixed(1)} GB free'),
          ],
          gradient: gradient,
        ),
        const SizedBox(height: 16),
        _buildSystemInfoCard(
          colorScheme,
          'Storage & Network',
          [
            _buildInfoColumn(colorScheme, 'Disk', _currentInfo.diskUsage / 100, '${_currentInfo.totalDisk.toStringAsFixed(1)} GB', '${_currentInfo.usedDisk.toStringAsFixed(1)} GB', Icons.disc_full, remainingText: '${_currentInfo.freeDisk.toStringAsFixed(1)} GB free'),
            _buildInfoColumn(colorScheme, 'Latency', _currentInfo.latency / 1000, '', '${_currentInfo.latency.toStringAsFixed(2)} ms', Icons.network_check, remainingText: "Ping"),
          ],
          gradient: gradient,
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard(ColorScheme colorScheme, String title, List<Widget> children, {required Gradient gradient}) {
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

  Widget _buildInfoColumn(ColorScheme colorScheme, String label, double progress, String total, String used, IconData icon, {String? remainingText}) {
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
                '${(progress * 100).toStringAsFixed(1)}%',
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
            '$used',
            style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
            overflow: TextOverflow.ellipsis,
          ),
          if (remainingText != null)
            Text(
              remainingText,
              style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}