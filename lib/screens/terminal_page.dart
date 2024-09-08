// lib/screens/terminal_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _TerminalPageState extends State<TerminalPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<TerminalEntry> _terminalOutput = [];
  bool _isLoading = false;
  SSHConnection? activeConnection;
  StreamSubscription<String>? _sessionSubscription;
  late SSHManager _sshManager;
  String _currentPrompt = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sshManager = SSHManager.getInstance();
    _fetchActiveConnection();
    _restoreTerminalState();
    _subscribeToTerminalOutput();
  }

  void _fetchActiveConnection() async {
    activeConnection = await ConnectionManager.getInstance().getActiveConnection();
    _updatePrompt();
    setState(() {});
  }

  void _updatePrompt() {
    if (activeConnection != null) {
      _currentPrompt = '[${activeConnection!.username}@${activeConnection!.hostId}]\$ ';
    } else {
      _currentPrompt = 'Not connected\$ ';
    }
  }

  void _restoreTerminalState() {
    final savedOutput = _sshManager.getSavedTerminalOutput();
    setState(() {
      _terminalOutput = savedOutput;
    });
    _scrollToBottom();
  }

  void _subscribeToTerminalOutput() {
    _sessionSubscription?.cancel();
    _sessionSubscription = _sshManager.terminalOutput?.listen((output) {
      setState(() {
        _terminalOutput.add(TerminalEntry(output));
        _sshManager.saveTerminalOutput(_terminalOutput);
      });
      _scrollToBottom();
    });
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
      _terminalOutput.add(TerminalEntry('$_currentPrompt$command', isCommand: true));
      _sshManager.saveTerminalOutput(_terminalOutput);
    });

    try {
      await _sshManager.sendCommand(command);
    } catch (e) {
      setState(() {
        _terminalOutput.add(TerminalEntry('Error: $e', isError: true));
        _sshManager.saveTerminalOutput(_terminalOutput);
      });
    } finally {
      setState(() {
        _isLoading = false;
        _commandController.clear();
      });
    }

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
            content: SingleChildScrollView(  // <-- Allow scrolling behavior for unbounded height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickCommandsBar(colorScheme),
                  SizedBox(
                    height: 400, // Set a height constraint to avoid the unbounded error
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
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SelectableText.rich(
          TextSpan(
            children: _terminalOutput.map((entry) {
              return TextSpan(
                text: '${entry.text}\n',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14,
                  color: entry.isCommand
                      ? Colors.green
                      : entry.isError
                      ? Colors.red
                      : Colors.white,
                ),
              );
            }).toList(),
          ),
          style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCommandInput(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(
              _currentPrompt,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _commandController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                ),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14,
                  color: Colors.white,
                ),
                onSubmitted: (_) => _sendCommand(),
              ),
            ),
            _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: _sendCommand,
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
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Clear Terminal',
            style: TextStyle(color: Colors.white),
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