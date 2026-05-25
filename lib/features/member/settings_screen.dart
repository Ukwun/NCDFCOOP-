import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart'
    as auth_controller;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _orderUpdatesEnabled = true;
  bool _promotionsEnabled = true;
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildToggleSetting(
              'Push Notifications',
              'Receive push notifications',
              _pushNotificationsEnabled,
              (value) => setState(() => _pushNotificationsEnabled = value),
            ),
            _buildToggleSetting(
              'Order Updates',
              'Get updates about your orders',
              _orderUpdatesEnabled,
              (value) => setState(() => _orderUpdatesEnabled = value),
            ),
            _buildToggleSetting(
              'Promotions',
              'Receive promotional offers',
              _promotionsEnabled,
              (value) => setState(() => _promotionsEnabled = value),
            ),
            const Divider(height: 32),

            // Display section
            _buildSectionHeader('Display'),
            _buildDropdownSetting(
              'Theme',
              _selectedTheme,
              const ['Light', 'Dark', 'System'],
              (value) => setState(() => _selectedTheme = value),
            ),
            _buildDropdownSetting(
              'Language',
              _selectedLanguage,
              const ['English', 'Spanish', 'French'],
              (value) => setState(() => _selectedLanguage = value),
            ),
            const Divider(height: 32),

            // Privacy & Support section
            _buildSectionHeader('Privacy & Support'),
            _buildLinkSetting('Privacy Policy', () {
              _openExternalLink(
                'https://coopcommerce.app/privacy',
                successMessage: 'Privacy Policy opened',
                failureMessage: 'Unable to open Privacy Policy right now',
              );
            }),
            _buildLinkSetting('Terms of Service', () {
              _openExternalLink(
                'https://coopcommerce.app/terms',
                successMessage: 'Terms of Service opened',
                failureMessage: 'Unable to open Terms of Service right now',
              );
            }),
            _buildLinkSetting('Help & Support', () {
              context.push('/help-support');
            }),
            const Divider(height: 32),

            // Account section
            _buildSectionHeader('Account'),
            _buildDangerousSetting(
              'Logout',
              'Sign out of your account',
              () => _showLogoutDialog(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: currentValue,
            items: options
                .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSetting(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerousSetting(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(auth_controller.authControllerProvider.notifier)
                    .signOut();
                if (context.mounted) {
                  context.go('/signin');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalLink(
    String url, {
    required String successMessage,
    required String failureMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(launched ? successMessage : failureMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
