import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'custom_scrollable_page.dart';
import '../services/core/ssh_manager.dart';
import '../services/core/connection_state_manager.dart' as csm;

class TerminalPage extends StatefulWidget {
  const TerminalPage({Key? key}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _terminalOutput = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      _isLoading = true;
      _terminalOutput.add('> $command');
    });

    final sshManager = SSHManager.getInstance();
    final result = await sshManager.executeCommand(command);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _terminalOutput.add(result);
      } else {
        _terminalOutput.add('Error executing command');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connectionStateManager = Provider.of<csm.ConnectionStateManager>(context);

    return CustomScrollablePage(
      title: 'Terminal',
      icon: Icons.terminal,
      showBottomNav: true,
      selectedIndex: 1,
      onBottomNavTap: (index) {
        // Handle navigation based on the tapped index
      },
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(connectionStateManager, colorScheme),
            const SizedBox(height: 16),
            _buildTerminalWindow(colorScheme),
            const SizedBox(height: 16),
            _buildCommandInput(colorScheme),
          ],
        ),
      ),
    );
  }


  Widget _buildConnectionStatus(csm.ConnectionStateManager connectionStateManager, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: connectionStateManager.state == csm.ConnectionState.connected
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            connectionStateManager.state == csm.ConnectionState.connected
                ? Icons.check_circle
                : Icons.error,
            color: connectionStateManager.state == csm.ConnectionState.connected
                ? colorScheme.primary
                : colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            connectionStateManager.state == csm.ConnectionState.connected
                ? 'Connected'
                : 'Disconnected',
            style: TextStyle(
              color: connectionStateManager.state == csm.ConnectionState.connected
                  ? colorScheme.primary
                  : colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTerminalWindow(ColorScheme colorScheme) {
    return Container(
      height: 300, // Set a fixed height or use a Flexible widget
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _terminalOutput.length,
        itemBuilder: (context, index) {
          final output = _terminalOutput[index];
          final isCommand = output.startsWith('> ');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              output,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                color: isCommand ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isCommand ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildCommandInput(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commandController,
            decoration: InputDecoration(
              hintText: 'Enter command',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
            ),
            onSubmitted: (_) => _sendCommand(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCommand,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(Icons.send),
        ),
      ],
    );
  }



}