import 'package:flutter/rendering.dart';

/// Performance optimization utilities
///
/// Provides methods to optimize app performance:
/// - Memory management
/// - Image optimization
/// - Caching strategies
/// - Profiling helpers
class PerformanceUtils {
  // Prevent instantiation
  PerformanceUtils._();

  // ==================== MEMORY OPTIMIZATION ====================
  /// Get current memory usage information
  static Future<MemoryInfo?> getMemoryInfo() async {
    // This requires platform channels to access native memory info
    // For now, we provide a basic structure
    try {
      // In production, use:
      // final info = await _platform.invokeMethod('getMemoryUsage');
      return MemoryInfo(
        usedMemory: 0,
        totalMemory: 0,
        freeMemory: 0,
      );
    } catch (e) {
      debugPrint('Error getting memory info: $e');
      return null;
    }
  }

  /// Clear image cache (trigger garbage collection)
  static Future<void> clearImageCache() async {
    // Clear image cache in Flutter
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Force garbage collection
  static Future<void> forceGarbageCollection() async {
    // Note: Dart automatically manages garbage collection
    // This is more of a suggestion
    debugPrint('Triggering garbage collection');
  }

  // ==================== IMAGE OPTIMIZATION ====================
  /// Get recommended image resolution based on screen size
  /// Note: For actual device pixel ratio, pass it as parameter or get from context
  static double getOptimalImageWidth(double screenWidth,
      {double devicePixelRatio = 2.0}) {
    // Return width optimized for device pixel ratio
    // This prevents loading 4K images on 1080p screens
    return screenWidth * devicePixelRatio;
  }

  /// Guidelines for image sizes
  ///
  /// Product Thumbnail: 200x200px @2x = 400x400px
  /// Product Full: 500x500px @2x = 1000x1000px
  /// Banner: 1080x400px (16:6 ratio)
  /// Profile: 200x200px @2x = 400x400px
  ///
  /// Compression recommendations:
  /// - Use WebP format when possible (smaller than PNG/JPG)
  /// - JPEG quality: 85-90 for photos
  /// - PNG: Use for images with transparency
  /// - Compress before uploading: TinyPNG, ImageOptim
  static const imageOptimizationGuidelines = '''
  IMAGE OPTIMIZATION GUIDELINES:
  
  Thumbnail Images (100-200px):
  - Use WebP format
  - 50-100 KB max
  - Square aspect ratio
  
  Product Images (300-500px):
  - Use WebP format
  - 100-300 KB max
  - Square aspect ratio
  
  Banner Images (full width):
  - Use WebP format
  - 300-600 KB max
  - 16:6 or 16:9 aspect ratio
  
  Profile Images (50-150px):
  - Use WebP format
  - 20-50 KB max
  - Square aspect ratio
  
  Compression Tools:
  - TinyPNG: https://tinypng.com
  - ImageOptim: https://imageoptim.com
  - WebP Converter: cwebp
  ''';

  // ==================== BUNDLE SIZE OPTIMIZATION ====================
  /// Guidelines for reducing app bundle size
  static const bundleSizeOptimization = '''
  BUNDLE SIZE OPTIMIZATION:
  
  Remove Unused Dependencies:
  1. Review pubspec.yaml for unused packages
  2. Check for duplicate functionality
  3. Remove debug-only packages from release
  
  Example (comments = remove in release):
  dev_dependencies:
    # - google_maps_flutter (only if not using)
    # - firebase_analytics (optional)
  
  Asset Optimization:
  1. Remove unused images and assets
  2. Compress all images (see imageOptimizationGuidelines)
  3. Delete unused animations/JSON files
  4. Check assets/ folder for duplicates
  
  Code Optimization:
  1. Enable Proguard for Android (minifyEnabled: true)
  2. Use shrinkResources: true
  3. Remove dead code
  4. Use tree-shaking (automatic in release builds)
  
  Android Specific:
  - Use App Bundle (aab) instead of APK for Play Store
  - Enable dynamic delivery
  - Use native libraries only if necessary
  
  iOS Specific:
  - Remove unused frameworks
  - Use asset slicing
  - Remove debug symbols in release
  
  Typical Bundle Sizes:
  - Minimal app: 20-30MB
  - Basic commerce app: 40-60MB
  - Full-featured app: 60-100MB
  
  Target for CoopCommerce: <50MB
  ''';

  // ==================== PROFILING HELPERS ====================
  /// Start performance timing
  ///
  /// Usage:
  /// ```dart
  /// final stopwatch = PerformanceUtils.startTimer('Load Products');
  /// // ... do work ...
  /// PerformanceUtils.stopTimer(stopwatch, 'Load Products');
  /// ```
  static Stopwatch startTimer(String label) {
    debugPrint('⏱️  Starting timer: $label');
    return Stopwatch()..start();
  }

  /// Stop performance timing and log result
  static void stopTimer(Stopwatch timer, String label) {
    timer.stop();
    final ms = timer.elapsedMilliseconds;

    if (ms < 100) {
      debugPrint('✅ $label: ${ms}ms (Fast)');
    } else if (ms < 500) {
      debugPrint('⚠️  $label: ${ms}ms (Medium)');
    } else {
      debugPrint('❌ $label: ${ms}ms (Slow)');
    }
  }

  /// Profile a function execution time
  static Future<T> profileAsync<T>(
    String label,
    Future<T> Function() function,
  ) async {
    final timer = startTimer(label);
    try {
      final result = await function();
      stopTimer(timer, label);
      return result;
    } catch (e) {
      stopTimer(timer, label);
      rethrow;
    }
  }

  /// Profile a sync function execution time
  static T profileSync<T>(
    String label,
    T Function() function,
  ) {
    final timer = startTimer(label);
    try {
      final result = function();
      stopTimer(timer, label);
      return result;
    } catch (e) {
      stopTimer(timer, label);
      rethrow;
    }
  }

  // ==================== DEVTOOLS GUIDES ====================
  static const devtoolsGuide = '''
  FLUTTER DEVTOOLS PERFORMANCE PROFILING:
  
  1. Start app with profile mode:
     flutter run --profile
  
  2. Open DevTools:
     - Chrome: chrome://inspect
     - Look for "Dart VM Service"
     - Click "Open DevTools"
  
  3. Performance Tab:
     - Record button at top
     - Watch for frames > 16.7ms (60 FPS threshold)
     - Red = jank, green = smooth
     - Drill down into slow frames
  
  4. Memory Tab:
     - Shows memory usage over time
     - Red peaks = memory spikes
     - Garbage collection events
     - Heap snapshots for leak detection
  
  5. CPU Profiler:
     - Shows which functions are expensive
     - Call stack analysis
     - Identifies hot spots
  
  Common Issues & Fixes:
  
  Jank (Frame > 16.7ms):
  - Use Selector to rebuild only affected widgets
  - Cache computed values
  - Lazy load large lists
  - Use const constructors
  
  Memory Leaks:
  - Dispose of listeners and subscriptions
  - Remove from collections when done
  - Cancel timers and animations
  - Check StreamSubscription cleanup
  
  Slow Image Loading:
  - Use CachedNetworkImage
  - Pre-cache images
  - Compress images
  - Use thumbnail sizes
  
  Slow List Scrolling:
  - Use ListView.builder instead of default
  - Cache widget calculations
  - Remove animations from list items
  - Reduce image quality in list
  ''';
}

/// Memory information container
class MemoryInfo {
  final int usedMemory;
  final int totalMemory;
  final int freeMemory;

  MemoryInfo({
    required this.usedMemory,
    required this.totalMemory,
    required this.freeMemory,
  });

  /// Get percentage of memory used
  double getUsagePercentage() {
    if (totalMemory == 0) return 0;
    return (usedMemory / totalMemory) * 100;
  }

  @override
  String toString() {
    return '''
    Memory Info:
      Used: ${(usedMemory / 1024 / 1024).toStringAsFixed(2)} MB
      Total: ${(totalMemory / 1024 / 1024).toStringAsFixed(2)} MB
      Free: ${(freeMemory / 1024 / 1024).toStringAsFixed(2)} MB
      Usage: ${getUsagePercentage().toStringAsFixed(1)}%
    ''';
  }
}
