import 'dart:async';
import '../services/ssh_manager.dart';

class SystemInfo {
  final double cpuUsage;
  final int cpuCores;
  final double totalRam;
  final double usedRam;
  final double freeRam;
  final double ramUsage;
  final double totalDisk;
  final double usedDisk;
  final double freeDisk;
  final double diskUsage;
  final double latency;

  SystemInfo({
    required this.cpuUsage,
    required this.cpuCores,
    required this.totalRam,
    required this.usedRam,
    required this.freeRam,
    required this.ramUsage,
    required this.totalDisk,
    required this.usedDisk,
    required this.freeDisk,
    required this.diskUsage,
    required this.latency,
  });

  factory SystemInfo.empty() {
    return SystemInfo(
      cpuUsage: 0,
      cpuCores: 0,
      totalRam: 0,
      usedRam: 0,
      freeRam: 0,
      ramUsage: 0,
      totalDisk: 0,
      usedDisk: 0,
      freeDisk: 0,
      diskUsage: 0,
      latency: 0,
    );
  }
}

class SystemInfoService {
  final SSHManager _sshManager = SSHManager.getInstance();
  final StreamController<SystemInfo> _controller = StreamController<SystemInfo>.broadcast();
  Timer? _timer;

  SystemInfoService() {
    _startFetching();
  }

  Stream<SystemInfo> get systemInfoStream => _controller.stream;

  void _startFetching() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchSystemInfo());
  }

  Future<void> _fetchSystemInfo() async {
    if (!_sshManager.isConnected()) {
      await _sshManager.connectWithSavedCredentials();
    }

    final cpuInfo = await _fetchCPUInfo();
    final memInfo = await _fetchMemInfo();
    final diskInfo = await _fetchDiskInfo();
    final latency = await _measureLatency();

    final systemInfo = SystemInfo(
      cpuUsage: cpuInfo['usage'] ?? 0,
      cpuCores: (cpuInfo['cores'] ?? 0).toInt(),
      totalRam: memInfo['total'] ?? 0,
      usedRam: memInfo['used'] ?? 0,
      freeRam: memInfo['free'] ?? 0,
      ramUsage: memInfo['usage'] ?? 0,
      totalDisk: diskInfo['total'] ?? 0,
      usedDisk: diskInfo['used'] ?? 0,
      freeDisk: diskInfo['free'] ?? 0,
      diskUsage: diskInfo['usage'] ?? 0,
      latency: latency,
    );

    _controller.add(systemInfo);
  }

  Future<Map<String, double>> _fetchCPUInfo() async {
    final result = await _sshManager.executeCommand(
        "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - \$1}'"
    );
    final cores = await _sshManager.executeCommand("nproc");

    return {
      'usage': double.tryParse(result?.trim() ?? '0') ?? 0,
      'cores': double.tryParse(cores?.trim() ?? '0') ?? 0,
    };
  }

  Future<Map<String, double>> _fetchMemInfo() async {
    final result = await _sshManager.executeCommand(
        "free -m | awk 'NR==2{printf \"%.2f %.2f %.2f %.2f\", \$2/1024, \$3/1024, \$4/1024, \$3*100/\$2 }'"
    );
    final parts = result?.split(' ');

    return {
      'total': double.tryParse(parts?[0] ?? '0') ?? 0,
      'used': double.tryParse(parts?[1] ?? '0') ?? 0,
      'free': double.tryParse(parts?[2] ?? '0') ?? 0,
      'usage': double.tryParse(parts?[3] ?? '0') ?? 0,
    };
  }

  Future<Map<String, double>> _fetchDiskInfo() async {
    final result = await _sshManager.executeCommand(
        "df -h / | awk 'NR==2{printf \"%.2f %.2f %.2f %.2f\", \$2, \$3, \$4, \$5}' | tr -d 'G%'"
    );
    final parts = result?.split(' ');

    return {
      'total': double.tryParse(parts?[0] ?? '0') ?? 0,
      'used': double.tryParse(parts?[1] ?? '0') ?? 0,
      'free': double.tryParse(parts?[2] ?? '0') ?? 0,
      'usage': double.tryParse(parts?[3] ?? '0') ?? 0,
    };
  }

  Future<double> _measureLatency() async {
    final startTime = DateTime.now();
    await _sshManager.executeCommand('echo');
    final endTime = DateTime.now();
    return endTime.difference(startTime).inMilliseconds.toDouble();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}