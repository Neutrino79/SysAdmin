// lib/screens/terminal_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/ConnectionStatusPill.dart';
import 'custom_scrollable_page.dart';
import '../services/core/ssh_manager.dart';
import '../services/core/connection_manager.dart';
import '../services/core/connection_state_manager.dart' as csm;
import '../widgets/connection_status_overlay.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({Key? key}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TerminalEntry> _terminalOutput = [];
  bool _isLoading = false;
  SSHConnection? activeConnection;
  StreamSubscription<String>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _fetchActiveConnection();
  }

  void _fetchActiveConnection() async {
    activeConnection = await ConnectionManager.getInstance().getActiveConnection();
    setState(() {});
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      _isLoading = true;
      _terminalOutput.add(TerminalEntry(command, isCommand: true));
    });

    final sshManager = SSHManager.getInstance();
    final result = await sshManager.executeCommand(command);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _terminalOutput.add(TerminalEntry(result));
      } else {
        _terminalOutput.add(TerminalEntry('Error executing command', isError: true));
      }
      _commandController.clear();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetTerminal() {
    setState(() {
      _terminalOutput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connectionStateManager = Provider.of<csm.ConnectionStateManager>(context);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollablePage(
            title: 'Terminal',
            icon: Icons.terminal,
            connectionStatusWidget: ConnectionStatusPill(
              connection: activeConnection,
              connectionState: connectionStateManager.state,
            ),
            showBottomNav: true,
            selectedIndex: 1,
            onBottomNavTap: (index) {
              // Handle navigation based on the tapped index
            },
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickCommandsBar(colorScheme),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _buildTerminalWindow(colorScheme),
                  ),
                  _buildCommandInput(colorScheme),
                  _buildResetButton(colorScheme),
                ],
              ),
            ),
          ),
          const ConnectionStatusOverlay(),
        ],
      ),
    );
  }

  Widget _buildQuickCommandsBar(ColorScheme colorScheme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickCommandChip(colorScheme, 'ls -la', Icons.list),
          _buildQuickCommandChip(colorScheme, 'ps aux', Icons.memory),
          _buildQuickCommandChip(colorScheme, 'df -h', Icons.storage),
          _buildQuickCommandChip(colorScheme, 'top', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(ColorScheme colorScheme, String command, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ActionChip(
        avatar: Icon(icon, color: colorScheme.primary),
        label: Text(command, style: TextStyle(color: colorScheme.onSurface)),
        onPressed: () {
          _commandController.text = command;
          _sendCommand();
        },
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTerminalWindow(ColorScheme colorScheme) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,  // Enable horizontal scrolling
            child: SizedBox(
              width: 600,  // Adjust the width to ensure horizontal scrollability
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _terminalOutput.length,
                itemBuilder: (context, index) {
                  final entry = _terminalOutput[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      entry.isCommand ? '> ${entry.text}' : entry.text,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        color: entry.isCommand
                            ? colorScheme.primary
                            : entry.isError
                            ? colorScheme.error
                            : colorScheme.onBackground,
                        fontWeight: entry.isCommand ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandInput(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commandController,
                decoration: InputDecoration(
                  hintText: 'Enter command',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                onSubmitted: (_) => _sendCommand(),
              ),
            ),
            IconButton(
              icon: _isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
                  : Icon(Icons.send, color: colorScheme.primary),
              onPressed: _isLoading ? null : _sendCommand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: ElevatedButton(
          onPressed: _resetTerminal,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Reset Terminal',
            style: TextStyle(color: colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

class TerminalEntry {
  final String text;
  final bool isCommand;
  final bool isError;

  TerminalEntry(this.text, {this.isCommand = false, this.isError = false});
}
