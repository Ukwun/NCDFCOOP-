import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Helper widget that displays either a local asset or network image
/// depending on the imageUrl path
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a local asset (starts with 'assets/')
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }

    // Otherwise treat as network image
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        return _buildErrorWidget(width: width, height: height);
      },
    );
  }

  Widget _buildErrorWidget({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

/// Helper for use in decoration backgrounds
class ProductImageProvider {
  static ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }
    return CachedNetworkImageProvider(imageUrl);
  }
}
