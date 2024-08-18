import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_scrollable_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WillPopScope(
        onWillPop: () async {
      // Show a dialog to confirm if the user wants to exit the app
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
    child: CustomScrollablePage(
      title: 'Dashboard',
      icon: Icons.airplay,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('heyy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          // Add more widgets here as needed
        ],
      ),
    ),
    );
  }
}