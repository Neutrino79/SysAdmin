import 'package:flutter/material.dart';

class CustomScrollablePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;
  final bool showDrawer;
  final bool showBottomNav;
  final List<BottomNavItem> bottomNavItems;
  final int selectedIndex;
  final Function(int) onBottomNavTap;
  final Color? drawerIconColor;
  final Widget? settingsWidget;
  final bool showSettings;
  final Widget? connectionStatusWidget; // New parameter

  const CustomScrollablePage({
    Key? key,
    required this.title,
    required this.icon,
    required this.content,
    this.showDrawer = true,
    this.showBottomNav = true,
    this.bottomNavItems = const [
      BottomNavItem(icon: Icons.home, label: 'Home'),
      BottomNavItem(icon: Icons.terminal, label: 'Terminal'),
      BottomNavItem(icon: Icons.list_alt, label: 'Logs'),
    ],
    this.selectedIndex = 0,
    required this.onBottomNavTap,
    this.drawerIconColor,
    this.settingsWidget,
    this.showSettings = true,
    this.connectionStatusWidget, // New parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      drawer: showDrawer ? _buildDrawer(context) : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              leading: showDrawer
                  ? Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    color: drawerIconColor ?? colorScheme.onPrimary,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              )
                  : null,
              actions: [
                if (connectionStatusWidget != null)
                  connectionStatusWidget!
                else if (showSettings)
                  settingsWidget ??
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: colorScheme.onPrimary,
                        onPressed: () {
                          // TODO: Implement settings action
                        },
                      ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(title, style: TextStyle(color: colorScheme.onPrimary)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAnimatedBackground(),
                    Center(
                      child: Icon(
                        icon,
                        size: 80,
                        color: colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: colorScheme.primary,
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? _buildBottomNavigationBar(colorScheme, context)
          : null,
    );
  }

  Widget _buildBottomNavigationBar(ColorScheme colorScheme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: bottomNavItems
            .map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        ))
            .toList(),
        currentIndex: selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        onTap: (index) {
          _onBottomNavTap(index, context);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _onBottomNavTap(int index, BuildContext context) {
    // Here we navigate to different routes based on the selected index.
    // For example, assume you have routes defined like `/home`, `/terminal`, and `/logs`.

    if (index == 0 && ModalRoute.of(context)?.settings.name != '/home') {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1 && ModalRoute.of(context)?.settings.name != '/terminal') {
      Navigator.pushReplacementNamed(context, '/terminal');
    } else if (index == 2 && ModalRoute.of(context)?.settings.name != '/logs') {
      Navigator.pushReplacementNamed(context, '/logs');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sys-Admin',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Empowering Linux anytime anywhere',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerSection(context, 'Main Features'),
          _buildDrawerItem(context, Icons.terminal, 'Terminal'),
          _buildDrawerItem(context, Icons.monitor, 'System Monitor'),
          _buildDrawerItem(context, Icons.security, 'SSH Manager'),
          _buildDrawerItem(context, Icons.person, 'User Administration'),
          _buildDrawerItem(context, Icons.group, 'Group Administration'),
          _buildDrawerItem(context, Icons.assignment, 'Logs Monitoring'),
          Divider(),
          _buildDrawerSection(context, 'More'),
          _buildDrawerItem(context, Icons.info, 'About Us'),
          _buildDrawerItem(context, Icons.contact_mail, 'Contact Us'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Made with 💛 by Neutrino79',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: drawerIconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Navigator.pop(context);
        if (title == 'SSH Manager') {
          Navigator.pushNamed(context, '/register');
        } else if (title == 'Terminal') {
          if (ModalRoute.of(context)?.settings.name != '/terminal') {
            Navigator.pushNamed(context, '/terminal');
          }
        } else {
          // Implement navigation to other features
        }
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(),
        );
      },
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.8)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.9, size.width, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
