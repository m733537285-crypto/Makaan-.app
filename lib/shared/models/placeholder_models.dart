import 'package:flutter/material.dart';

import '../../core/localization/localized_text.dart';

enum PlaceholderDemoKind { none, success, error, dialog, sheet }

enum PlaceholderSectionStyle { bullets, chips, stats }

class PlaceholderAction {
  const PlaceholderAction({
    required this.label,
    required this.icon,
    this.routeName,
    this.demoKind = PlaceholderDemoKind.none,
    this.isPrimary = true,
  });

  final LocalizedText label;
  final IconData icon;
  final String? routeName;
  final PlaceholderDemoKind demoKind;
  final bool isPrimary;
}

class PlaceholderSection {
  const PlaceholderSection({
    required this.title,
    required this.items,
    this.style = PlaceholderSectionStyle.bullets,
  });

  final LocalizedText title;
  final List<LocalizedText> items;
  final PlaceholderSectionStyle style;
}

class PlaceholderStat {
  const PlaceholderStat({required this.label, required this.value});

  final LocalizedText label;
  final String value;
}

class FeatureSpec {
  const FeatureSpec({
    required this.title,
    required this.subtitle,
    required this.screenKey,
    required this.icon,
    required this.highlights,
    required this.actions,
    required this.sections,
    required this.stats,
    this.navIndex,
    this.showSearch = false,
    this.showFab = false,
    this.fabRoute,
    this.fabLabel,
  });

  final LocalizedText title;
  final LocalizedText subtitle;
  final String screenKey;
  final IconData icon;
  final List<LocalizedText> highlights;
  final List<PlaceholderAction> actions;
  final List<PlaceholderSection> sections;
  final List<PlaceholderStat> stats;
  final int? navIndex;
  final bool showSearch;
  final bool showFab;
  final String? fabRoute;
  final LocalizedText? fabLabel;
}
