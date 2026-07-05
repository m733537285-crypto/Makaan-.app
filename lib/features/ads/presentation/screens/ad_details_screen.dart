import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../widgets/ad_ui.dart';

class AdDetailsScreenArgs {
  const AdDetailsScreenArgs({required this.adId});

  final String adId;
}

class AdDetailsScreen extends StatefulWidget {
  const AdDetailsScreen({super.key, this.args});

  final AdDetailsScreenArgs? args;

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AdListing? ad = widget.args?.adId == null
        ? (controller.featuredAds.isNotEmpty ? controller.featuredAds.first : null)
        : controller.findAdById(widget.args!.adId);

    return AppScaffold(
      title: ad?.title ?? 'تفاصيل الإعلان',
      body: ad == null
          ? const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 860),
                  child: EmptyStateCard(
                    title: 'الإعلان غير متاح',
                    subtitle: 'قد يكون تم حذفه أو تغيرت حالته.',
                  ),
                ),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _ImageGallery(
                              images: ad.images,
                              currentIndex: _currentImageIndex,
                              onPageChanged: (int index) => setState(() => _currentImageIndex = index),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                DealBadge(ad: ad),
                                AdStatusChip(status: ad.effectiveStatus),
                                AdMetaChip(icon: Icons.category_outlined, label: ad.category.arabicLabel),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(ad.title, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 10),
                            AdPriceSummary(ad: ad, highlight: true),
                            const SizedBox(height: 14),
                            Text(ad.description, style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                AdMetaChip(icon: Icons.person_outline_rounded, label: ad.ownerName ?? 'مستخدم مكان'),
                                AdMetaChip(icon: Icons.phone_outlined, label: ad.phoneNumber),
                                AdMetaChip(icon: Icons.location_on_outlined, label: ad.locationText),
                                AdMetaChip(icon: Icons.photo_library_outlined, label: '${ad.images.length} صور'),
                                AdMetaChip(icon: Icons.schedule_outlined, label: DateTimeFormatter.shortDateTime(ad.createdAt)),
                                if (ad.expiresAt != null)
                                  AdMetaChip(
                                    icon: Icons.timer_outlined,
                                    label: 'ينتهي ${DateTimeFormatter.shortDateTime(ad.expiresAt!)}',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                AppPrimaryButton(
                                  label: 'اتصال مباشر',
                                  icon: Icons.phone_forwarded_outlined,
                                  onPressed: () => _copyContact(ad.phoneNumber),
                                ),
                                AppSecondaryButton(
                                  label: controller.isFavoriteAd(ad.adId) ? 'حذف من المفضلة' : 'إضافة للمفضلة',
                                  icon: controller.isFavoriteAd(ad.adId) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  onPressed: () => _toggleFavorite(controller, ad.adId),
                                ),
                                AppSecondaryButton(
                                  label: 'مشاركة',
                                  icon: Icons.share_outlined,
                                  onPressed: () => _shareAd(ad),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('ملخص الإعلان', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 14),
                            _DetailRow(label: 'رقم الإعلان', value: ad.adId),
                            _DetailRow(label: 'التصنيف', value: ad.category.arabicLabel),
                            _DetailRow(label: 'الحالة', value: ad.effectiveStatus.arabicLabel),
                            _DetailRow(label: 'نوع العرض', value: ad.dealType.arabicLabel),
                            _DetailRow(label: 'السعر الحالي', value: '${ad.priceAfter.round()} ر.ي'),
                            _DetailRow(
                              label: 'السعر قبل الخصم',
                              value: ad.priceBefore > 0 ? '${ad.priceBefore.round()} ر.ي' : 'غير محدد',
                            ),
                            _DetailRow(
                              label: 'نسبة الخصم',
                              value: ad.discountPercent > 0 ? '${ad.discountPercent}%' : 'لا يوجد',
                            ),
                            _DetailRow(label: 'وقت النشر', value: DateTimeFormatter.shortDateTime(ad.createdAt)),
                            _DetailRow(
                              label: 'انتهاء العرض',
                              value: ad.expiresAt == null ? 'اختياري / غير محدد' : DateTimeFormatter.shortDateTime(ad.expiresAt!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }


  Future<void> _toggleFavorite(AppController controller, String adId) async {
    final bool added = await controller.toggleFavoriteAd(adId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added ? 'تمت الإضافة إلى المفضلة.' : 'تم الحذف من المفضلة.')),
    );
  }

  Future<void> _copyContact(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نسخ رقم التواصل: $phoneNumber')),
    );
  }

  Future<void> _shareAd(AdListing ad) async {
    final String text = 'إعلان على مكان\n${ad.title}\nالسعر: ${ad.priceAfter.round()} ر.ي\nالموقع: ${ad.locationText}\nالتواصل: ${ad.phoneNumber}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ نص مشاركة الإعلان إلى الحافظة.')),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (BuildContext context, int index) {
              final String image = images.isEmpty ? '' : images[index];
              return AdImageView(imageUrl: image, height: 320, borderRadius: 24);
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: List<Widget>.generate(
            images.isEmpty ? 1 : images.length,
            (int index) => AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: currentIndex == index ? 22 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
