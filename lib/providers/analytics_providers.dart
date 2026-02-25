import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/models/analytics_models.dart';
import 'package:coop_commerce/services/analytics_service.dart';

/// Analytics service provider
final analyticsServiceProvider = Provider((ref) {
  return AnalyticsService();
});

/// Dashboard KPI summary
final dashboardSummaryProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getDashboardSummary();
});

/// Sales metrics for today
final todaySalesMetricsProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getSalesMetrics(DateTime.now());
});

/// Sales metrics for last 7 days
final salesMetricsLast7DaysProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getSalesMetricsLast7Days();
});

/// Engagement metrics for today
final todayEngagementMetricsProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getEngagementMetrics(DateTime.now());
});

/// Inventory analytics for today
final todayInventoryAnalyticsProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getInventoryAnalytics(DateTime.now());
});

/// Logistics performance for today
final todayLogisticsPerformanceProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getLogisticsPerformance(DateTime.now());
});

/// Review analytics for today
final todayReviewAnalyticsProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getReviewAnalytics(DateTime.now());
});

/// Member analytics for today
final todayMemberAnalyticsProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getMemberAnalytics(DateTime.now());
});

/// Top products by revenue
final topProductsByRevenueProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  final today = DateTime.now();
  final thirtyDaysAgo = today.subtract(Duration(days: 30));

  return service.getTopProductsByRevenue(
    limit: 10,
    startDate: thirtyDaysAgo,
    endDate: today,
  );
});

/// Top products by rating
final topProductsByRatingProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getTopProductsByRating(limit: 10);
});

/// Sales metrics for specific date (family provider)
final salesMetricsForDateProvider =
    FutureProvider.family<SalesMetrics?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getSalesMetrics(date);
});

/// Engagement metrics for specific date (family provider)
final engagementMetricsForDateProvider =
    FutureProvider.family<EngagementMetrics?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getEngagementMetrics(date);
});

/// Inventory analytics for specific date (family provider)
final inventoryAnalyticsForDateProvider =
    FutureProvider.family<InventoryAnalytics?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getInventoryAnalytics(date);
});

/// Logistics performance for specific date (family provider)
final logisticsPerformanceForDateProvider =
    FutureProvider.family<LogisticsPerformance?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getLogisticsPerformance(date);
});

/// Review analytics for specific date (family provider)
final reviewAnalyticsForDateProvider =
    FutureProvider.family<ReviewAnalytics?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getReviewAnalytics(date);
});

/// Member analytics for specific date (family provider)
final memberAnalyticsForDateProvider =
    FutureProvider.family<MemberAnalytics?, DateTime>((ref, date) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getMemberAnalytics(date);
});

/// Monthly sales growth percentage
final monthlySalesGrowthProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  final today = DateTime.now();
  final thisMonth = await service.getSalesMetrics(today);

  final lastMonthDate = DateTime(today.year, today.month - 1, today.day);
  final lastMonth = await service.getSalesMetrics(lastMonthDate);

  if (thisMonth == null || lastMonth == null) return 0.0;
  if (lastMonth.totalRevenue == 0) return 0.0;

  return ((thisMonth.totalRevenue - lastMonth.totalRevenue) /
          lastMonth.totalRevenue) *
      100;
});

/// Monthly user growth percentage
final monthlyUserGrowthProvider = FutureProvider((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  final today = DateTime.now();
  final thisMonth = await service.getEngagementMetrics(today);

  final lastMonthDate = DateTime(today.year, today.month - 1, today.day);
  final lastMonth = await service.getEngagementMetrics(lastMonthDate);

  if (thisMonth == null || lastMonth == null) return 0.0;
  if (lastMonth.totalUsers == 0) return 0.0;

  return ((thisMonth.totalUsers - lastMonth.totalUsers) /
          lastMonth.totalUsers) *
      100;
});

/// Dashboard health status
final dashboardHealthStatusProvider = FutureProvider((ref) async {
  final summary = await ref.watch(dashboardSummaryProvider.future);
  return summary.getHealthStatus();
});
