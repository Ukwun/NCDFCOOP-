import 'package:flutter/material.dart';
import 'app_constants.dart';

// String Extensions
extension StringExtensions on String {
  bool isValidEmail() {
    final emailRegex = RegExp(AppConstants.emailPattern);
    return emailRegex.hasMatch(this);
  }

  bool isValidPhone() {
    final phoneRegex = RegExp(AppConstants.phonePattern);
    return phoneRegex.hasMatch(replaceAll(' ', ''));
  }

  bool isValidUrl() {
    final urlRegex = RegExp(AppConstants.urlPattern);
    return urlRegex.hasMatch(this);
  }

  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String capitalizeWords() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isNumeric {
    if (isEmpty) return false;
    return double.tryParse(this) != null;
  }

  String limitLength(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  String toCamelCase() {
    List<String> words = split(' ');
    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      result += words[i].capitalize();
    }
    return result;
  }

  String toSnakeCase() {
    return replaceAllMapped(
      RegExp(r'(?<=[a-z])[A-Z]|(?<=[A-Z])[A-Z](?=[a-z])'),
      (Match m) => '_${m.group(0)}',
    ).toLowerCase();
  }

  String removeAllWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  String truncate(int length, {String ellipsis = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length - ellipsis.length)}$ellipsis';
  }
}

// Number Extensions
extension NumberExtensions on num {
  String toCurrencyString({String symbol = '\$'}) {
    return '$symbol${abs().toStringAsFixed(2)}';
  }

  String toFormattedString({int decimalPlaces = 2}) {
    return toStringAsFixed(decimalPlaces);
  }

  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  T clamp<T extends num>(T min, T max) {
    if (this < min) return min;
    if (this > max) return max;
    return this as T;
  }

  String toPercentageString({int decimalPlaces = 2}) {
    return '${toStringAsFixed(decimalPlaces)}%';
  }

  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
}

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool isTomorrow() {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool isThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 7));
    return isAfter(weekStart) && isBefore(weekEnd);
  }

  bool isThisMonth() {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool isThisYear() {
    return year == DateTime.now().year;
  }

  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  String toFormattedDate({String format = 'MMM dd, yyyy'}) {
    // Simple formatting - can be enhanced with intl package
    return toString().split(' ')[0];
  }

  String toFormattedTime({bool include24Hour = false}) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// List Extensions
extension ListExtensions<T> on List<T> {
  bool isNullOrEmpty() {
    return isEmpty;
  }

  T? getOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  List<T> removeDuplicates() {
    final seen = <T>{};
    return where((item) => seen.add(item)).toList();
  }

  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  List<T> whereNot(bool Function(T) test) {
    return where((item) => !test(item)).toList();
  }
}

// Map Extensions
extension MapExtensions<K, V> on Map<K, V> {
  bool isNullOrEmpty() {
    return isEmpty;
  }

  V? getOrNull(K key) {
    return this[key];
  }

  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }

  Map<K, V> filter(bool Function(K key, V value) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(key, value)) {
        result[key] = value;
      }
    });
    return result;
  }
}

// Duration Extensions
extension DurationExtensions on Duration {
  String toFormattedString() {
    final hours = inHours;
    final minutes = inMinutes % 60;
    final seconds = inSeconds % 60;

    String result = '';
    if (hours > 0) result += '${hours}h ';
    if (minutes > 0) result += '${minutes}m ';
    if (seconds > 0 || result.isEmpty) result += '${seconds}s';

    return result.trim();
  }

  bool isLongerThan(Duration other) {
    return inMilliseconds > other.inMilliseconds;
  }

  bool isShorterThan(Duration other) {
    return inMilliseconds < other.inMilliseconds;
  }
}

// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  double get bottomPadding => MediaQuery.of(this).viewInsets.bottom;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
}
