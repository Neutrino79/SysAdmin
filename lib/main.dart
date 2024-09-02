import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'services/connection_manager.dart';
import 'services/ssh_manager.dart';
import 'services/connection_state_manager.dart';
import 'screens/welcome_page.dart';
import 'screens/register_connection_page.dart';
import 'screens/home_page.dart';
import 'widgets/connection_status_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connectionManager = ConnectionManager.getInstance();
  final sshManager = SSHManager.getInstance();
  final initialRoute = await getInitialRoute(connectionManager, sshManager);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ConnectionStateManager(),
      child: SysAdminApp(initialRoute: initialRoute),
    ),
  );
}

Future<String> getInitialRoute(ConnectionManager connectionManager, SSHManager sshManager) async {
  final connections = await connectionManager.getConnections();
  if (connections.isEmpty) {
    return '/welcome';
  } else {
    final activeConnection = await connectionManager.getActiveConnection();
    if (activeConnection != null) {
      try {
        final connected = await sshManager.connectWithSavedCredentials();
        if (connected) {
          return '/home';
        } else {
          await connectionManager.deactivateCurrentConnection();
          return '/register';
        }
      } catch (e) {
        print('Error connecting with saved credentials: $e');
        await connectionManager.deactivateCurrentConnection();
        return '/register';
      }
    } else {
      return '/register';
    }
  }
}

class SysAdminApp extends StatelessWidget {
  final String initialRoute;

  const SysAdminApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SysAdmin',
          theme: ThemeData(
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          initialRoute: initialRoute,
          routes: {
            '/welcome': (context) => const WelcomePage(),
            '/register': (context) => const RegisterConnectionPage(),
            '/home': (context) => const SysAdminWrapper(child: HomePage(), currentRouteName: '/home'),
          },
        );
      },
    );
  }
}

class SysAdminWrapper extends StatelessWidget {
  const SysAdminWrapper({Key? key, required this.child, required this.currentRouteName}) : super(key: key);

  final Widget child;
  final String currentRouteName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          if (currentRouteName == '/home')
            const ConnectionStatusOverlay(),
        ],
      ),
    );
  }
}