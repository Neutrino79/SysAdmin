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

class GroupAdministrationPage extends StatefulWidget {
  const GroupAdministrationPage({Key? key}) : super(key: key);

  @override
  _GroupAdministrationPageState createState() => _GroupAdministrationPageState();
}

class _GroupAdministrationPageState extends State<GroupAdministrationPage> {
  final SSHManager _sshManager = SSHManager.getInstance();
  final ConnectionManager _connectionManager = ConnectionManager.getInstance();
  SSHConnection? activeConnection;

  List<GroupModel> _groups = [];
  List<String> _availableUsers = [];
  bool _isLoading = true;
  bool _isLoadingUsers = true;
  final _addGroupFormKey = GlobalKey<FormBuilderState>();
  final ScrollController _scrollController = ScrollController();
  String? _searchQuery;
  List<GroupModel> get _filteredGroups => _searchQuery?.isNotEmpty == true
      ? _groups.where((group) =>
  group.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
      group.members.any((member) => member.toLowerCase().contains(_searchQuery!.toLowerCase()))
  ).toList()
      : _groups;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _fetchGroups(),
      _fetchUsers(),
      _fetchActiveConnection(),
    ] as Iterable<Future>);
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
    setState(() => _isLoadingUsers = true);
    try {
      final usersOutput = await _sshManager.executeCommand(
          'getent passwd | cut -d: -f1'
      );
      if (usersOutput != null) {
        setState(() {
          _availableUsers = usersOutput.split('\n')
              .where((user) => user.isNotEmpty)
              .toList();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    try {
      final activeConnection = await _connectionManager.getActiveConnection();
      if (activeConnection == null) {
        _showErrorSnackBar('No active connection');
        return;
      }

      final groupsOutput = await _sshManager.executeCommand(
          'getent group'
      );
      if (groupsOutput != null) {
        setState(() {
          _groups = _parseGroups(groupsOutput);
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch groups: $e');
      setState(() => _isLoading = false);
    }
  }

  List<GroupModel> _parseGroups(String groupContent) {
    return groupContent.split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split(':');
      return GroupModel(
        name: parts[0],
        password: parts[1],
        gid: parts[2],
        members: parts.length > 3 ? parts[3].split(',')
            .where((m) => m.isNotEmpty)
            .toList() : [],
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _showAddGroupBottomSheet() {
    if (_isLoadingUsers) {
      _showErrorSnackBar('Loading users list...');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildBottomSheetHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: FormBuilder(
                    key: _addGroupFormKey,
                    child: Column(
                      children: [
                        _buildGroupFormFields(),
                        const SizedBox(height: 16),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.group_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Create New Group',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          name: 'groupname',
          label: 'Group Name',
          icon: Icons.group,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'Group name is required'),
            FormBuilderValidators.minLength(2, errorText: 'Minimum 2 characters'),
            FormBuilderValidators.maxLength(32, errorText: 'Maximum 32 characters'),
                (value) {
              final groupNameRegex = RegExp(r'^[a-z_][a-z0-9_-]*$');
              return value != null && groupNameRegex.hasMatch(value)
                  ? null
                  : 'Invalid group name format (lowercase letters, numbers, underscore, hyphen)';
            },
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          'Group Members',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FormBuilderFilterChip(
          name: 'members',
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          spacing: 8,
          runSpacing: 8,
          options: _availableUsers.map((user) => FormBuilderChipOption(
            value: user,
            child: Text(user),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Select users to add to the group',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _addNewGroup,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
      ),
      child: Text(
        'Create Group',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _addNewGroup() async {
    if (_addGroupFormKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _addGroupFormKey.currentState!.value;
      final groupname = formValues['groupname'] as String;
      final members = (formValues['members'] as List<String>?)?.join(',');

      try {
        String groupAddCommand = 'sudo groupadd $groupname';
        if (members?.isNotEmpty == true) {
          for (final member in members!.split(',')) {
            groupAddCommand += ' && sudo usermod -a -G $groupname ${member.trim()}';
          }
        }

        final result = await _sshManager.executeCommand(groupAddCommand);

        if (result != null && result.isEmpty) {
          _showSuccessSnackBar('Group $groupname created successfully');
          _fetchGroups();
          Navigator.pop(context);
        } else {
          _showErrorSnackBar('Failed to create group: $result');
        }
      } catch (e) {
        _showErrorSnackBar('Error creating group: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
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
            title: 'Group Administration',
            icon: Icons.groups,
            connectionStatusWidget: ConnectionStatusPill(
              connection: activeConnection,
              connectionState: connectionStateManager.state,
            ),
            showBottomNav: true,
            bottomNavItems: const [
              BottomNavItem(icon: Icons.group, label: 'Groups'),
              BottomNavItem(icon: Icons.terminal, label: 'Terminal'),
              BottomNavItem(icon: Icons.list_alt, label: 'Logs'),
            ],
            selectedIndex: 0,
            onBottomNavTap: (index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/terminal');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/logs');
                  break;
              }
            },
            content: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSearchBar(),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildGroupList(),
                        // Add extra padding at bottom to account for FAB
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const ConnectionStatusOverlay(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64.0),
        child: FloatingActionButton.extended(
          onPressed: _showAddGroupBottomSheet,
          icon: const Icon(Icons.group_add),
          label: const Text('Add Group'),
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSearchBar(),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildGroupList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search groups...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildGroupList() {
    if (_filteredGroups.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,  // Add this
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery?.isNotEmpty == true
                    ? 'No groups found matching "$_searchQuery"'
                    : 'No groups found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }



    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildGroupListItem(group),
          ),
        );
      },
    );
  }

  Widget _buildGroupListItem(GroupModel group) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            group.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          group.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.tag,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'GID: ${group.gid}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditGroupDialog(group),
              tooltip: 'Edit group',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _confirmDeleteGroup(group),
              tooltip: 'Delete group',
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Members',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                group.members.isEmpty
                    ? Text(
                  'No members',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.members.map((member) => Chip(
                    label: Text(member),
                    deleteIcon: const Icon(Icons.person_remove, size: 18),
                    onDeleted: () => _removeUserFromGroup(member, group),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddMembersDialog(group),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Members'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(GroupModel group) {
    // Implement group editing functionality
    // This could include changing group name or GID
  }

  void _showAddMembersDialog(GroupModel group) {
    final selectedUsers = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() {
                    // Implement user search
                  }),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = _availableUsers[index];
                      final isSelected = selectedUsers.contains(user);
                      final isCurrentMember = group.members.contains(user);

                      return CheckboxListTile(
                        title: Text(user),
                        value: isSelected,
                        enabled: !isCurrentMember,
                        onChanged: isCurrentMember ? null : (selected) {
                          setState(() {
                            if (selected == true) {
                              selectedUsers.add(user);
                            } else {
                              selectedUsers.remove(user);
                            }
                          });
                        },
                        subtitle: isCurrentMember
                            ? Text(
                          'Already a member',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addUsersToGroup(selectedUsers, group);
            },
            child: const Text('Add Selected'),
          ),
        ],
      ),
    );
  }

  Future<void> _addUsersToGroup(List<String> users, GroupModel group) async {
    if (users.isEmpty) return;

    try {
      final commands = users.map((user) =>
      'sudo usermod -a -G ${group.name} $user'
      ).join(' && ');

      final result = await _sshManager.executeCommand(commands);

      if (result != null && result.isEmpty) {
        _showSuccessSnackBar('Added ${users.length} users to ${group.name}');
        _fetchGroups();
      } else {
        _showErrorSnackBar('Failed to add users: $result');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding users: $e');
    }
  }

  Future<void> _removeUserFromGroup(String user, GroupModel group) async {
    try {
      final result = await _sshManager.executeCommand(
          'sudo gpasswd -d $user ${group.name}'
      );

      if (result != null && result.isEmpty) {
        _showSuccessSnackBar('Removed $user from ${group.name}');
        _fetchGroups();
      } else {
        _showErrorSnackBar('Failed to remove user: $result');
      }
    } catch (e) {
      _showErrorSnackBar('Error removing user: $e');
    }
  }

  void _confirmDeleteGroup(GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete group ${group.name}?'),
            if (group.members.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Warning: This group has ${group.members.length} members.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteGroup(group.name);
    }
  }

  Future<void> _deleteGroup(String groupName) async {
    try {
      final result = await _sshManager.executeCommand(
          'sudo groupdel $groupName'
      );

      if (result != null && result.isEmpty) {
        _showSuccessSnackBar('Group $groupName deleted successfully');
        _fetchGroups();
      } else {
        _showErrorSnackBar('Failed to delete group: $result');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting group: $e');
    }
  }
}

class GroupModel {
  final String name;
  final String password;
  final String gid;
  final List<String> members;

  GroupModel({
    required this.name,
    required this.password,
    required this.gid,
    required this.members,
  });
}