import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Data model for user
class UserAccount {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<UserRole> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });
}

/// Provider for user list
final userListProvider = FutureProvider<List<UserAccount>>((ref) async {
  // TODO: Integrate with actual user service
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    UserAccount(
      id: 'user-001',
      name: 'John Doe',
      email: 'john@coop.com',
      phone: '08012345678',
      roles: [UserRole.consumer, UserRole.coopMember],
      isActive: true,
      createdAt: DateTime(2025, 6, 15),
      lastLogin: DateTime.now().subtract(const Duration(days: 2)),
    ),
    UserAccount(
      id: 'user-002',
      name: 'Jane Smith',
      email: 'jane@franchise.com',
      phone: '08087654321',
      roles: [UserRole.franchiseOwner],
      isActive: true,
      createdAt: DateTime(2025, 7, 1),
      lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
});

/// User Management Screen
class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  String searchQuery = '';
  String? selectedRoleFilter;
  bool showInactive = false;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading users: $error'),
            ],
          ),
        ),
        data: (users) => Column(
          children: [
            // Search and Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                  const SizedBox(height: 12),

                  // Filters
                  Row(
                    children: [
                      // Role filter
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedRoleFilter,
                          hint: const Text('All Roles'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Roles'),
                            ),
                            ...UserRole.values.map((role) => DropdownMenuItem(
                                  value: role.name,
                                  child: Text(role.displayName),
                                )),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedRoleFilter = value),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Show inactive toggle
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: showInactive,
                              onChanged: (value) =>
                                  setState(() => showInactive = value ?? false),
                            ),
                            const Text(
                              'Show Inactive',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User list
            Expanded(
              child: _buildUsersList(users),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<UserAccount> users) {
    // Filter users
    var filtered = users.where((user) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        if (!user.name.toLowerCase().contains(searchQuery) &&
            !user.email.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }

      // Role filter
      if (selectedRoleFilter != null) {
        if (!user.roles.any((role) => role.name == selectedRoleFilter)) {
          return false;
        }
      }

      // Active filter
      if (!showInactive && !user.isActive) {
        return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No users found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _UserCard(
        user: filtered[index],
        onEdit: () => _showEditUserDialog(filtered[index]),
        onToggleActive: () => _toggleUserStatus(filtered[index]),
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    List<UserRole> selectedRoles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Assign Roles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...UserRole.values.map((role) => CheckboxListTile(
                      title: Text(role.displayName),
                      value: selectedRoles.contains(role),
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call user service to create user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'User ${nameController.text} created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserAccount user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    List<UserRole> selectedRoles = List.from(user.roles);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Roles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...UserRole.values.map((role) => CheckboxListTile(
                      title: Text(role.displayName),
                      value: selectedRoles.contains(role),
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call user service to update user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User ${nameController.text} updated'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleUserStatus(UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(
          user.isActive
              ? 'Deactivate this user? They will not be able to login.'
              : 'Activate this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call user service to toggle status
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    user.isActive ? 'User deactivated' : 'User activated',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}

/// User Card Widget
class _UserCard extends StatelessWidget {
  final UserAccount user;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: user.isActive
                                    ? Colors.green.shade700
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Roles and info
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...user.roles.map((role) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        role.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                if (user.lastLogin != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Last: ${_formatDate(user.lastLogin!)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onToggleActive,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.isActive ? Colors.red : Colors.green,
                    side: BorderSide(
                      color: user.isActive ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
