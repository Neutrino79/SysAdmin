import 'package:flutter/material.dart';
import '../services/ssh_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _commandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _commandController,
              decoration: InputDecoration(labelText: 'Enter command'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final sshManager = SSHManager.getInstance();
                final result = await sshManager.executeCommand(_commandController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result ?? 'No result')),
                );
              },
              child: Text('Execute Command'),
            ),
          ],
        ),
      ),
    );
  }
}