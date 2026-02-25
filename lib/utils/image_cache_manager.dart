import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Manages image caching for the application
///
/// Provides:
/// - Efficient image caching with expiry
/// - Compressed image display
/// - Placeholder and error handling
/// - Memory and disk cache optimization
class ImageCacheManager {
  // Prevent instantiation
  ImageCacheManager._();

  // ==================== CONFIGURATION ====================
  /// Custom cache manager with specific settings
  static late CacheManager _customCacheManager;

  /// Maximum cache size in bytes (100MB)
  static const int maxCacheSize = 104857600;

  /// Cache duration in days
  static const int cacheDurationDays = 7;

  // ==================== INITIALIZATION ====================
  /// Initialize the image cache manager
  /// Call this in main.dart during app startup
  static Future<void> initialize() async {
    _customCacheManager = CacheManager(
      Config(
        'coop_commerce_images',
        stalePeriod: Duration(days: cacheDurationDays),
        maxNrOfCacheObjects: 100,
      ),
    );

    // Clear cache if needed
    // await _customCacheManager.emptyCache();
  }

  // ==================== CLEANUP ====================
  /// Clear all cached images
  static Future<void> clearCache() async {
    await _customCacheManager.emptyCache();
  }

  /// Get current cache size
  static Future<int> getCacheSize() async {
    try {
      // Note: CacheManager doesn't provide direct access to cache size
      // This is a simplified implementation
      // In production, consider using package:flutter_cache_manager with custom store
      return maxCacheSize; // Theoretical max, actual may vary
    } catch (e) {
      // Return 0 if we can't determine cache size
      return 0;
    }
  }

  // ==================== PRODUCT IMAGE DISPLAY ====================
  /// Display a cached product image with loading and error states
  ///
  /// Parameters:
  ///   - imageUrl: The full URL of the image
  ///   - width: Width of the image (optional)
  ///   - height: Height of the image (optional)
  ///   - fit: How to fit the image in the box
  static Widget cachedProductImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: _customCacheManager,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  // ==================== USER PROFILE IMAGE ====================
  /// Display a cached user profile image
  /// Creates a circular avatar
  static Widget cachedProfileImage({
    required String? imageUrl,
    required double radius,
    String? userName,
  }) {
    // Use initials if no image
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          userName?.isNotEmpty ?? false
              ? userName!.characters.first.toUpperCase()
              : '?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(
        imageUrl,
        cacheManager: _customCacheManager,
      ),
      onBackgroundImageError: (exception, stackTrace) {
        // Handle error - show fallback
      },
    );
  }

  // ==================== BANNER/HERO IMAGE ====================
  /// Display a cached banner or hero image
  /// Often larger images with aspect ratio
  static Widget cachedBannerImage({
    required String imageUrl,
    double aspectRatio = 16 / 9,
    BoxFit fit = BoxFit.cover,
  }) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        cacheManager: _customCacheManager,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  // ==================== THUMBNAIL IMAGE ====================
  /// Display a small cached thumbnail image
  /// Used in lists and grids
  static Widget cachedThumbnailImage({
    required String imageUrl,
    double size = 100,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheManager: _customCacheManager,
      memCacheWidth: size.toInt() * 2, // Device pixel ratio
      memCacheHeight: size.toInt() * 2,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 24),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  /// Pre-cache an image (load it before needed)
  /// Useful for images that will appear soon
  static Future<void> preCacheImage({
    required String imageUrl,
  }) async {
    await _customCacheManager.downloadFile(imageUrl);
  }

  /// Pre-cache multiple images
  static Future<void> preCacheImages({
    required List<String> imageUrls,
  }) async {
    for (final url in imageUrls) {
      await preCacheImage(imageUrl: url);
    }
  }

  /// Get file from cache synchronously if available
  static Future<String?> getCachedImagePath({
    required String imageUrl,
  }) async {
    final file = await _customCacheManager.getSingleFile(imageUrl);
    return file.path;
  }

  /// Remove specific image from cache
  static Future<void> removeCachedImage({
    required String imageUrl,
  }) async {
    await _customCacheManager.removeFile(imageUrl);
  }
}
