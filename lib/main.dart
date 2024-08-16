import 'package:flutter/material.dart';
import 'services/connection_manager.dart';
import 'screens/welcome_page.dart';
import 'screens/register_connection_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connectionManager = ConnectionManager.getInstance();
  final initialRoute = await connectionManager.getInitialRoute();
  runApp(SysAdminApp(initialRoute: initialRoute));
}

class SysAdminApp extends StatelessWidget {
  final String initialRoute;

  const SysAdminApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SysAdmin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/register': (context) => const RegisterConnectionPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}