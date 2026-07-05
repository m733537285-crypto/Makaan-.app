import 'package:flutter/material.dart';

import '../../../../shared/models/ad_models.dart';
import '../../../../shared/utils/date_time_formatter.dart';
import '../../../../shared/widgets/optimized_image.dart';

class AdImageView extends StatelessWidget {
  const AdImageView({
    required this.imageUrl,
    this.height = 180,
    this.borderRadius = 24,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0) as double;
    return OptimizedImageView(
      imageUrl: imageUrl,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
      cacheWidth: (720 * devicePixelRatio).round(),
    );
  }
}

class AdStatusChip extends StatelessWidget {
  const AdStatusChip({required this.status, super.key});

  final AdStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.arabicLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _color(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _color(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (status) {
      case AdStatus.active:
        return const Color(0xFF059669);
      case AdStatus.pending:
        return scheme.secondary;
      case AdStatus.expired:
        return scheme.onSurfaceVariant;
      case AdStatus.rejected:
        return scheme.error;
    }
  }
}

class DealBadge extends StatelessWidget {
  const DealBadge({required this.ad, super.key});

  final AdListing ad;

  @override
  Widget build(BuildContext context) {
    final String label = ad.dealType == DealType.standard
        ? (ad.discountPercent > 0 ? 'خصم ${ad.discountPercent}%' : 'إعلان جديد')
        : ad.dealType.arabicLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF97316), Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdPriceSummary extends StatelessWidget {
  const AdPriceSummary({required this.ad, this.highlight = false, super.key});

  final AdListing ad;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          '${_formatCurrency(ad.priceAfter)} ر.ي',
          style: theme.textTheme.titleLarge?.copyWith(
            color: highlight ? theme.colorScheme.primary : null,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (ad.priceBefore > 0)
          Text(
            '${_formatCurrency(ad.priceBefore)} ر.ي',
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (ad.discountPercent > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'خصم ${ad.discountPercent}%',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  static String _formatCurrency(double value) {
    final int rounded = value.round();
    final String digits = rounded.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class AdMetaChip extends StatelessWidget {
  const AdMetaChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class AdCard extends StatelessWidget {
  const AdCard({
    required this.ad,
    required this.onTap,
    this.compact = false,
    this.showStatus = false,
    super.key,
  });

  final AdListing ad;
  final VoidCallback onTap;
  final bool compact;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  AdImageView(imageUrl: ad.primaryImage, height: compact ? 150 : 190, borderRadius: 20),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: DealBadge(ad: ad),
                  ),
                  if (showStatus)
                    PositionedDirectional(
                      top: 10,
                      end: 10,
                      child: AdStatusChip(status: ad.effectiveStatus),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                ad.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                ad.description,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              AdPriceSummary(ad: ad),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  AdMetaChip(icon: Icons.category_outlined, label: ad.category.arabicLabel),
                  AdMetaChip(icon: Icons.location_on_outlined, label: ad.locationText),
                  AdMetaChip(icon: Icons.schedule_outlined, label: DateTimeFormatter.relativeArabic(ad.createdAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({required this.title, required this.subtitle, this.icon = Icons.campaign_outlined, super.key});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.height, required this.borderRadius});

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.image_outlined, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(height: 8),
          Text('صورة الإعلان', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
