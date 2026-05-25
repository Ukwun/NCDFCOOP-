import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight JSON cache for offline fallback reads.
class LocalCacheService {
  static const String _productsKey = 'cache_products_v1';
  static const String _memberDataPrefix = 'cache_member_data_';
  static const String _ordersPrefix = 'cache_orders_';

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey, jsonEncode(products));
  }

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_productsKey);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> cacheMemberData(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_memberDataPrefix$userId', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedMemberData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_memberDataPrefix$userId');
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> cacheUserOrders(
    String userId,
    List<Map<String, dynamic>> orders,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_ordersPrefix$userId', jsonEncode(orders));
  }

  Future<List<Map<String, dynamic>>> getCachedUserOrders(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_ordersPrefix$userId');
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
