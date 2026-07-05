import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../core/localization/localized_text.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_state_widgets.dart';
import '../models/placeholder_models.dart';
import 'app_buttons.dart';
import 'app_input_fields.dart';
import 'common_component_showcase.dart';

enum PreviewState { content, loading, error, empty, success }

class FeaturePlaceholderScreen extends StatefulWidget {
  const FeaturePlaceholderScreen({required this.spec, super.key});

  final FeatureSpec spec;

  @override
  State<FeaturePlaceholderScreen> createState() =>
      _FeaturePlaceholderScreenState();
}

class _FeaturePlaceholderScreenState extends State<FeaturePlaceholderScreen> {
  PreviewState _state = PreviewState.content;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.spec.title.resolve(context),
      currentNavIndex: widget.spec.navIndex,
      floatingActionButton: widget.spec.showFab && widget.spec.fabRoute != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(widget.spec.fabRoute!),
              label: Text(widget.spec.fabLabel?.resolve(context) ?? ''),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width =
              constraints.maxWidth > AppBreakpoints.maxContentWidth
              ? AppBreakpoints.maxContentWidth
              : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildPreviewController(context),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStateBody(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: <Color>[scheme.primaryContainer, scheme.surface],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppBrandLockup(compact: true),
            const SizedBox(height: 18),
            Text(
              widget.spec.title.resolve(context),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.spec.subtitle.resolve(context),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.spec.highlights
                  .map(
                    (LocalizedText item) =>
                        Chip(label: Text(item.resolve(context))),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.spec.stats
                  .map(
                    (PlaceholderStat stat) => _StatCard(
                      label: stat.label.resolve(context),
                      value: stat.value,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewController(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'معاينة الحالات',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'اختر أي حالة لاختبار رسائل التحميل والخطأ والفراغ والنجاح على الشاشة الحالية.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<PreviewState>(
                segments: const <ButtonSegment<PreviewState>>[
                  ButtonSegment(
                    value: PreviewState.content,
                    label: Text('المحتوى'),
                  ),
                  ButtonSegment(
                    value: PreviewState.loading,
                    label: Text('تحميل'),
                  ),
                  ButtonSegment(value: PreviewState.error, label: Text('خطأ')),
                  ButtonSegment(value: PreviewState.empty, label: Text('فارغ')),
                  ButtonSegment(
                    value: PreviewState.success,
                    label: Text('نجاح'),
                  ),
                ],
                selected: <PreviewState>{_state},
                onSelectionChanged: (Set<PreviewState> value) {
                  setState(() {
                    _state = value.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateBody(BuildContext context) {
    switch (_state) {
      case PreviewState.loading:
        return const AppLoadingState(key: ValueKey<String>('loading'));
      case PreviewState.error:
        return const AppMessageState(
          key: ValueKey<String>('error'),
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل البيانات',
          message: 'هذه معاينة لرسائل الخطأ وإمكانية إعادة المحاولة.',
          color: Colors.red,
        );
      case PreviewState.empty:
        return const AppMessageState(
          key: ValueKey<String>('empty'),
          icon: Icons.inbox_outlined,
          title: 'لا توجد بيانات حالياً',
          message:
              'يمكن استخدام هذه الحالة عند عدم وجود نتائج أو طلبات أو إشعارات.',
          color: Colors.orange,
        );
      case PreviewState.success:
        return const AppMessageState(
          key: ValueKey<String>('success'),
          icon: Icons.check_circle_outline_rounded,
          title: 'تم تنفيذ الإجراء بنجاح',
          message: 'معاينة لرسائل النجاح بعد الإرسال أو الحفظ أو النشر.',
          color: Colors.green,
        );
      case PreviewState.content:
        return KeyedSubtree(
          key: const ValueKey<String>('content'),
          child: Column(
            children: <Widget>[
              if (widget.spec.showSearch) ...<Widget>[
                const AppSearchField(hint: 'ابحث داخل هذه الشاشة'),
                const SizedBox(height: 18),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.spec.actions
                        .map(
                          (PlaceholderAction action) => action.isPrimary
                              ? AppPrimaryButton(
                                  label: action.label.resolve(context),
                                  icon: action.icon,
                                  onPressed: () => _handleAction(action),
                                )
                              : AppSecondaryButton(
                                  label: action.label.resolve(context),
                                  icon: action.icon,
                                  onPressed: () => _handleAction(action),
                                ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...widget.spec.sections.map((PlaceholderSection section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _SectionCard(section: section),
                );
              }),
              const CommonComponentShowcase(),
            ],
          ),
        );
    }
  }

  Future<void> _handleAction(PlaceholderAction action) async {
    if (action.routeName != null) {
      await Navigator.of(context).pushNamed(action.routeName!);
      return;
    }

    switch (action.demoKind) {
      case PlaceholderDemoKind.success:
        AppDialogs.showSuccessSnackBar(context, 'تم تنفيذ الإجراء التجريبي');
      case PlaceholderDemoKind.error:
        AppDialogs.showErrorSnackBar(
          context,
          'تعذر تنفيذ الإجراء في المعاينة الحالية',
        );
      case PlaceholderDemoKind.dialog:
        await AppDialogs.showConfirmationDialog(
          context: context,
          title: 'تأكيد الإجراء',
          message: 'هذه نافذة منبثقة قابلة لإعادة الاستخدام داخل التطبيق.',
          onConfirm: () =>
              AppDialogs.showSuccessSnackBar(context, 'تم التأكيد'),
        );
      case PlaceholderDemoKind.sheet:
        await AppDialogs.showActionSheet(context);
      case PlaceholderDemoKind.none:
        return;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final PlaceholderSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              section.title.resolve(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            switch (section.style) {
              PlaceholderSectionStyle.chips => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: section.items
                    .map(
                      (LocalizedText item) =>
                          Chip(label: Text(item.resolve(context))),
                    )
                    .toList(),
              ),
              PlaceholderSectionStyle.stats => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: section.items
                    .map(
                      (LocalizedText item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                        ),
                        child: Text(item.resolve(context)),
                      ),
                    )
                    .toList(),
              ),
              PlaceholderSectionStyle.bullets => Column(
                children: section.items
                    .map(
                      (LocalizedText item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline_rounded),
                        title: Text(item.resolve(context)),
                      ),
                    )
                    .toList(),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
