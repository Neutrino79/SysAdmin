import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../services/core/ssh_manager.dart';
import '../services/core/connection_manager.dart';
import 'custom_scrollable_page.dart';
import '../widgets/connection_status_overlay.dart';
import '../widgets/ConnectionStatusPill.dart';
import '../services/core/connection_state_manager.dart' as csm;

class UserAdministrationPage extends StatefulWidget {
  const UserAdministrationPage({Key? key}) : super(key: key);

  @override
  _UserAdministrationPageState createState() => _UserAdministrationPageState();
}

class _UserAdministrationPageState extends State<UserAdministrationPage> {
  final SSHManager _sshManager = SSHManager.getInstance();
  final ConnectionManager _connectionManager = ConnectionManager.getInstance();
  SSHConnection? activeConnection;

  List<UserModel> _users = [];
  bool _isLoading = true;
  final _addUserFormKey = GlobalKey<FormBuilderState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchActiveConnection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchActiveConnection() async {
    activeConnection = await ConnectionManager.getInstance().getActiveConnection();
    setState(() {});
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final activeConnection = await _connectionManager.getActiveConnection();
      if (activeConnection == null) {
        _showErrorSnackBar('No active connection');
        return;
      }

      final usersOutput = await _sshManager.executeCommand(
          'getent passwd | cut -d: -f1,3,4,6,7 | grep -E ":[1-9][0-9]{3,}"'
      );
      if (usersOutput != null) {
        setState(() {
          _users = _parseUsers(usersOutput);
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch users: $e');
      setState(() => _isLoading = false);
    }
  }

  List<UserModel> _parseUsers(String passwdContent) {
    return passwdContent.split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split(':');
      return UserModel(
        username: parts[0],
        uid: parts[1],
        gid: parts[2],
        homeDirectory: parts[3],
        shell: parts[4],
      );
    }).toList();
  }

  void _showAddUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildBottomSheetHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FormBuilder(
                    key: _addUserFormKey,
                    child: Column(
                      children: [
                        _buildUserFormFields(),
                        const SizedBox(height: 16),
                        _buildSubmitButton(),
                        const SizedBox(height: 32), // Extra padding at bottom
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Add New User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserFormFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildFormField(
          name: 'username',
          label: 'Username',
          icon: Icons.person,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'Username is required'),
            FormBuilderValidators.minLength(3, errorText: 'Minimum 3 characters'),
            FormBuilderValidators.maxLength(32, errorText: 'Maximum 32 characters'),
                (value) {
              final usernameRegex = RegExp(r'^[a-z_][a-z0-9_-]*$');
              return value != null && usernameRegex.hasMatch(value)
                  ? null
                  : 'Invalid username format';
            },
          ]),
        ),
        _buildFormField(
          name: 'fullName',
          label: 'Full Name',
          icon: Icons.badge,
          validator: FormBuilderValidators.required(errorText: 'Full name is required'),
        ),
        _buildFormField(
          name: 'password',
          label: 'Password',
          icon: Icons.lock,
          isPassword: true,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'Password is required'),
            FormBuilderValidators.minLength(8, errorText: 'Minimum 8 characters'),
          ]),
        ),
        const SizedBox(height: 24),
        _buildUserTypeSelector(),
      ],
    );
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FormBuilderTextField(
        name: name,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return FormBuilderChoiceChip(
      name: 'userType',
      decoration: InputDecoration(
        labelText: 'User Permissions',
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
      ),
      alignment: WrapAlignment.center,
      spacing: 8.0,
      selectedColor: Theme.of(context).colorScheme.primary,
      options: [
        FormBuilderChipOption(
          value: 'standard',
          child: Text('Standard User'),
        ),
        FormBuilderChipOption(
          value: 'sudo',
          child: Text('Sudo Access'),
        ),
        FormBuilderChipOption(
          value: 'admin',
          child: Text('Full Admin'),
        ),
      ],
      validator: FormBuilderValidators.required(errorText: 'Select user type'),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _addNewUser,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
      ),
      child: Text(
        'Create User',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addNewUser() async {
    if (_addUserFormKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _addUserFormKey.currentState!.value;
      final username = formValues['username'];
      final fullName = formValues['fullName'];
      final password = formValues['password'];
      final userType = formValues['userType'];

      try {
        String userAddCommand = _constructUserAddCommand(
            username,
            fullName,
            password,
            userType
        );

        final result = await _sshManager.executeCommand(userAddCommand);

        if (result != null && result.isEmpty) {
          _showSuccessSnackBar('User $username created successfully');
          _fetchUsers();
          Navigator.pop(context);
        } else {
          _showErrorSnackBar('Failed to create user: $result');
        }
      } catch (e) {
        _showErrorSnackBar('Error creating user: $e');
      }
    }
  }

  String _constructUserAddCommand(
      String username,
      String fullName,
      String password,
      String userType
      ) {
    String baseCommand = 'sudo useradd -m -c "$fullName" $username';

    switch (userType) {
      case 'sudo':
        baseCommand += ' && sudo usermod -aG sudo $username';
        break;
      case 'admin':
        baseCommand += ' && sudo usermod -aG sudo,adm,wheel $username';
        break;
    }

    baseCommand += ' && echo "$username:$password" | sudo chpasswd';

    return baseCommand;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionStateManager = Provider.of<csm.ConnectionStateManager>(context);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollablePage(
            title: 'User Administration',
            icon: Icons.people,
            connectionStatusWidget: ConnectionStatusPill(
              connection: activeConnection,
              connectionState: connectionStateManager.state,
            ),
            showBottomNav: true,
            selectedIndex: 2,
            onBottomNavTap: (index) {
            },
            content: _buildContent(),
          ),
          const ConnectionStatusOverlay(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64.0), // Adjust this value based on your bottom nav height
        child: FloatingActionButton.extended(
          onPressed: _showAddUserBottomSheet,
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildUserList(),
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _users.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserListItem(user);
        },
      ),
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Text(
          user.username[0].toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.username,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'UID: ${user.uid}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user.homeDirectory,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => _confirmDeleteUser(user.username),
      ),
    );
  }

  void _confirmDeleteUser(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete user $username?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteUser(username);
    }
  }

  void _deleteUser(String username) async {
    try {
      final deleteCommand = 'sudo userdel -r $username';
      final result = await _sshManager.executeCommand(deleteCommand);

      if (result != null && result.isEmpty) {
        _showSuccessSnackBar('User $username deleted successfully');
        _fetchUsers();
      } else {
        _showErrorSnackBar('Failed to delete user: $result');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting user: $e');
    }
  }
}

class UserModel {
  final String username;
  final String uid;
  final String gid;
  final String homeDirectory;
  final String shell;

  UserModel({
    required this.username,
    required this.uid,
    required this.gid,
    required this.homeDirectory,
    required this.shell,
  });
}