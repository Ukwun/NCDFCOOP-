import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// App-wide settings that affect the entire application
class AppSettings {
  final bool darkMode;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool marketingEmails;
  final bool locationServices;
  final bool biometricAuth;
  final String language;

  AppSettings({
    this.darkMode = false,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.marketingEmails = false,
    this.locationServices = true,
    this.biometricAuth = false,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'pushNotifications': pushNotifications,
    'emailNotifications': emailNotifications,
    'marketingEmails': marketingEmails,
    'locationServices': locationServices,
    'biometricAuth': biometricAuth,
    'language': language,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    darkMode: json['darkMode'] ?? false,
    pushNotifications: json['pushNotifications'] ?? true,
    emailNotifications: json['emailNotifications'] ?? true,
    marketingEmails: json['marketingEmails'] ?? false,
    locationServices: json['locationServices'] ?? true,
    biometricAuth: json['biometricAuth'] ?? false,
    language: json['language'] ?? 'en',
  );

  AppSettings copyWith({
    bool? darkMode,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? marketingEmails,
    bool? locationServices,
    bool? biometricAuth,
    String? language,
  }) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    marketingEmails: marketingEmails ?? this.marketingEmails,
    locationServices: locationServices ?? this.locationServices,
    biometricAuth: biometricAuth ?? this.biometricAuth,
    language: language ?? this.language,
  );
}

/// Handles app settings persistence
class AppSettingsPersistence {
  static const String _settingsKey = 'coop_commerce_app_settings';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Save settings
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      await _secureStorage.write(key: _settingsKey, value: json);
      print('✅ Settings saved');
    } catch (e) {
      print('❌ Error saving settings: $e');
    }
  }

  /// Load settings
  static Future<AppSettings> loadSettings() async {
    try {
      final json = await _secureStorage.read(key: _settingsKey);
      if (json == null) {
        return AppSettings();
      }
      final data = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings.fromJson(data);
    } catch (e) {
      print('❌ Error loading settings: $e');
      return AppSettings();
    }
  }
}

/// Notifier for app settings
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return await AppSettingsPersistence.loadSettings();
  }

  /// Update dark mode setting
  /// This automatically updates the global theme for the entire app
  Future<void> setDarkMode(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(darkMode: enabled);
    // Update state immediately for reactive theme change across entire app
    state = AsyncValue.data(newSettings);
    // Persist the setting
    await AppSettingsPersistence.saveSettings(newSettings);
    print('🌙 Dark mode: ${enabled ? 'ON' : 'OFF'}');
  }

  /// Update push notifications
  Future<void> setPushNotifications(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(pushNotifications: enabled);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }

  /// Update email notifications
  Future<void> setEmailNotifications(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(emailNotifications: enabled);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }

  /// Update marketing emails
  Future<void> setMarketingEmails(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(marketingEmails: enabled);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }

  /// Update location services
  Future<void> setLocationServices(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(locationServices: enabled);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }

  /// Update biometric auth
  Future<void> setBiometricAuth(bool enabled) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(biometricAuth: enabled);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }

  /// Update language
  Future<void> setLanguage(String language) async {
    final currentSettings = state.value ?? AppSettings();
    final newSettings = currentSettings.copyWith(language: language);
    state = AsyncValue.data(newSettings);
    await AppSettingsPersistence.saveSettings(newSettings);
  }
}

/// Riverpod provider for app settings
final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Convenience provider for dark mode only - watches app settings and always stays in sync
/// This provider is used by the MaterialApp to reactively update the theme globally
final darkModeProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  // Extract dark mode value and ensure immediate theme update across entire app
  // When appSettingsProvider updates, this provider automatically recomputes
  // which triggers MaterialApp rebuild with new theme
  return settingsAsync.maybeWhen(
    data: (settings) => settings.darkMode,
    orElse: () => false,
  );
});
