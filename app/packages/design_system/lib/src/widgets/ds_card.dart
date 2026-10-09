import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation = 0,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double elevation;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
