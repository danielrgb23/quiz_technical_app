import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:home_module/home_module.dart';

class HomeItemCard extends StatelessWidget {
  const HomeItemCard({super.key, required this.item});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: () => context.router.pushPath(AppRoutes.homeDetailPath(item.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
