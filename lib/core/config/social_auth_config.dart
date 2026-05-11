class SocialAuthConfig {
  static const String _facebookAppId =
      String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: '');
  static const String _facebookClientToken =
      String.fromEnvironment('FACEBOOK_CLIENT_TOKEN', defaultValue: '');

  static bool get isFacebookConfigured {
    return _isConfigured(_facebookAppId) && _isConfigured(_facebookClientToken);
  }

  static String get facebookUnavailableMessage {
    return 'Facebook sign-in is temporarily unavailable while configuration is completed.';
  }

  static bool _isConfigured(String value) {
    return value.isNotEmpty && !value.contains('FACEBOOK_');
  }
}
