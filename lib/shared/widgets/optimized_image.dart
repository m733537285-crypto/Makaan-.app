import 'package:flutter/material.dart';

class OptimizedImageView extends StatelessWidget {
  const OptimizedImageView({
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    super.key,
  });

  final String imageUrl;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    final String cleaned = imageUrl.trim();
    if (cleaned.isEmpty) {
      return _ImageFallback(height: height, borderRadius: borderRadius);
    }
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: cleaned.startsWith('http')
            ? Image.network(
                cleaned,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _ImageFallback(height: height, borderRadius: borderRadius);
                },
                frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: child,
                  );
                },
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return _ImageLoading(progress: loadingProgress);
                },
              )
            : Image.asset(
                cleaned,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                filterQuality: FilterQuality.medium,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _ImageFallback(height: height, borderRadius: borderRadius);
                },
              ),
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading({required this.progress});

  final ImageChunkEvent progress;

  @override
  Widget build(BuildContext context) {
    final int? expected = progress.expectedTotalBytes;
    final double? value = expected == null ? null : progress.cumulativeBytesLoaded / expected;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(value: value, strokeWidth: 2.6),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.height, required this.borderRadius});

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant, size: 34),
    );
  }
}
