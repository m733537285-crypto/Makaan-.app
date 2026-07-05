import 'package:flutter/material.dart';

import '../../../../shared/models/feature_catalog.dart';
import '../../../../shared/widgets/feature_placeholder_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScreen(spec: FeatureCatalog.support);
  }
}
