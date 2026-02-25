import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../welcome/auth_provider.dart' as auth_controller;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsUI(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading settings: $err')),
      ),
    );
  }

  Widget _buildSettingsUI(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // NOTIFICATIONS
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingTile(
            context,
            'Push Notifications',
            'Receive push notifications for orders & updates',
            settings.pushNotifications,
            (val) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setPushNotifications(val);
              if (context.mounted) {
                _showSavedFeedback(context,
                    'Push notifications ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          _buildSettingTile(
            context,
            'Email Notifications',
            'Receive email updates about your account',
            settings.emailNotifications,
            (val) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setEmailNotifications(val);
              if (context.mounted) {
                _showSavedFeedback(context,
                    'Email notifications ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          _buildSettingTile(
            context,
            'Marketing Emails',
            'Get exclusive offers and promotions',
            settings.marketingEmails,
            (val) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setMarketingEmails(val);
              if (context.mounted) {
                _showSavedFeedback(context,
                    'Marketing emails ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          const Divider(),

          // PREFERENCES
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingTile(
            context,
            'Dark Mode',
            'Use dark theme for the entire app',
            settings.darkMode,
            (val) async {
              await ref.read(appSettingsProvider.notifier).setDarkMode(val);
              if (context.mounted) {
                _showSavedFeedback(
                    context, 'Dark mode ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          _buildSettingTile(
            context,
            'Location Services',
            'Allow location access for better service',
            settings.locationServices,
            (val) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setLocationServices(val);
              if (context.mounted) {
                _showSavedFeedback(context,
                    'Location services ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          _buildSettingTile(
            context,
            'Biometric Authentication',
            'Use fingerprint or face unlock',
            settings.biometricAuth,
            (val) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setBiometricAuth(val);
              if (context.mounted) {
                _showSavedFeedback(
                    context, 'Biometric auth ${val ? 'enabled' : 'disabled'}');
              }
            },
          ),
          const Divider(),

          // ACCOUNT
          _buildSectionHeader(context, 'Account'),
          _buildActionTile(
            context,
            'Change Password',
            'Update your password',
            Icons.lock_outline,
            () => _changePassword(context),
          ),
          _buildActionTile(
            context,
            'Change Language',
            'Select your preferred language',
            Icons.language,
            () => _changeLanguage(context),
          ),
          const Divider(),

          // DANGER ZONE
          _buildSectionHeader(context, 'Danger Zone'),
          _buildActionTile(
            context,
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_outline,
            () => _deleteAccount(context),
            isDestructive: true,
          ),
          _buildActionTile(
            context,
            'Logout',
            'Sign out of your account',
            Icons.logout,
            () => _logout(context, ref),
            isDestructive: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          onChanged(newValue).then((_) {
            print('✅ Setting updated: $title = $newValue');
          }).catchError((e) {
            print('❌ Error updating $title: $e');
          });
        },
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _changeLanguage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change language - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _showSavedFeedback(context, 'Account deletion initiated');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await ref
                  .read(auth_controller.authControllerProvider.notifier)
                  .signOut();
              if (context.mounted) {
                _showSavedFeedback(context, 'Logged out successfully');
                Future.delayed(const Duration(milliseconds: 500), () {
                  context.go('/welcome');
                });
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSavedFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
