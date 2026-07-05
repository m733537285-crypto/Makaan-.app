import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';

class AppRoundLogo extends StatelessWidget {
  const AppRoundLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(AppAssets.appIcon, width: size, height: size);
  }
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppRoundLogo(size: compact ? 44 : 56),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'مكان',
              style: compact ? textTheme.titleLarge : textTheme.headlineSmall,
            ),
            Text(
              'كل خدماتك في مكان واحد',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
