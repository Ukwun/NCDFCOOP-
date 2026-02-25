import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/cart_activity_logger.dart';
import 'package:coop_commerce/core/services/review_activity_logger.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';

/// Activity tracker provider
final activityTrackerProvider = Provider((ref) => ActivityTrackingService());

/// Cart activity logger provider
final cartActivityLoggerProvider = Provider((ref) {
  final tracker = ref.watch(activityTrackerProvider);
  return CartActivityLogger(tracker);
});

/// Review activity logger provider
final reviewActivityLoggerProvider = Provider((ref) {
  final tracker = ref.watch(activityTrackerProvider);
  return ReviewActivityLogger(tracker);
});
