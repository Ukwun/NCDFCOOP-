import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsUI(
          context,
          ref,
          settings,
          settingsNotifier,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSettingsUI(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppSettingsNotifier notifier,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Notification Settings
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingTile(
            context,
            'Push Notifications',
            'Receive push notifications',
            settings.pushNotifications,
            (val) => notifier.setPushNotifications(val),
          ),
          _buildSettingTile(
            context,
            'Email Notifications',
            'Receive email updates',
            settings.emailNotifications,
            (val) => notifier.setEmailNotifications(val),
          ),
          _buildSettingTile(
            context,
            'Marketing Emails',
            'Marketing and promotional emails',
            settings.marketingEmails,
            (val) => notifier.setMarketingEmails(val),
          ),
          const Divider(),

          // Preferences
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingTile(
            context,
            'Dark Mode',
            'Use dark theme for the entire app',
            settings.darkMode,
            (val) => notifier.setDarkMode(val),
          ),
          _buildSettingTile(
            context,
            'Location Services',
            'Allow location access',
            settings.locationServices,
            (val) => notifier.setLocationServices(val),
          ),
          _buildSettingTile(
            context,
            'Biometric Authentication',
            'Use fingerprint or face unlock',
            settings.biometricAuth,
            (val) => notifier.setBiometricAuth(val),
          ),
          const Divider(),

          // Account Settings
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

          // Danger Zone
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
            color: Theme.of(context).primaryColor,
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
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
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

  void _changeLanguage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change language - Coming soon'),
        duration: Duration(seconds: 2),
      ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion initiated'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
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
            onPressed: () {
              context.pop();
              context.go('/welcome');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
