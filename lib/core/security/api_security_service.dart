import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// API Security Service - Handles secure API communication
class ApiSecurityService {
  static const String baseUrl =
      'https://api.coopcommerce.com/v1'; // Use HTTPS only
  static const Duration timeout = Duration(seconds: 30);

  /// Make a secure GET request
  static Future<http.Response> secureGet(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getSecureHeaders(requiresAuth);
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.get(uri, headers: headers).timeout(timeout);
      _validateResponse(response);

      return response;
    } catch (e) {
      debugPrint('GET request error: $e');
      rethrow;
    }
  }

  /// Make a secure POST request
  static Future<http.Response> securePost(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getSecureHeaders(requiresAuth);
      final uri = Uri.parse('$baseUrl$endpoint');

      // Validate body for injection attacks
      final sanitizedBody = _sanitizeRequestBody(body);

      final response = await http
          .post(
            uri,
            headers: headers,
            body: sanitizedBody,
          )
          .timeout(timeout);

      _validateResponse(response);
      return response;
    } catch (e) {
      debugPrint('POST request error: $e');
      rethrow;
    }
  }

  /// Make a secure PUT request
  static Future<http.Response> securePut(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getSecureHeaders(requiresAuth);
      final uri = Uri.parse('$baseUrl$endpoint');
      final sanitizedBody = _sanitizeRequestBody(body);

      final response = await http
          .put(
            uri,
            headers: headers,
            body: sanitizedBody,
          )
          .timeout(timeout);

      _validateResponse(response);
      return response;
    } catch (e) {
      debugPrint('PUT request error: $e');
      rethrow;
    }
  }

  /// Make a secure DELETE request
  static Future<http.Response> secureDelete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getSecureHeaders(requiresAuth);
      final uri = Uri.parse('$baseUrl$endpoint');

      final response =
          await http.delete(uri, headers: headers).timeout(timeout);
      _validateResponse(response);

      return response;
    } catch (e) {
      debugPrint('DELETE request error: $e');
      rethrow;
    }
  }

  /// Get secure headers with authentication
  static Future<Map<String, String>> _getSecureHeaders(
      bool requiresAuth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Version': '1.0',
      'X-Client-Version': '1.0.0',
      // Add CSRF token if available
      'X-Requested-With': 'XMLHttpRequest',
    };

    if (requiresAuth) {
      final token = await SecureStorageService.getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Validate API response
  static void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        // Token expired, handle logout
        _handleUnauthorized();
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode}');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    }
  }

  /// Handle unauthorized access
  static void _handleUnauthorized() {
    // Clear secure data and redirect to login
    SecureStorageService.clearAllSecureData();
    // Implement redirect to login screen in your app
    debugPrint('Session expired. Please log in again.');
  }

  /// Sanitize request body to prevent injection
  static Map<String, dynamic> _sanitizeRequestBody(Map<String, dynamic> body) {
    final sanitized = <String, dynamic>{};

    body.forEach((key, value) {
      if (value is String) {
        // Remove potentially harmful characters
        sanitized[key] = value
            .replaceAll('<script>', '')
            .replaceAll('</script>', '')
            .replaceAll('<iframe>', '')
            .replaceAll('</iframe>', '');
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }
}
