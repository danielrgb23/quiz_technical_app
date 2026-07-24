import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:home_module/home_module.dart';

import '../bloc/home_item_detail_cubit.dart';

@RoutePage()
class HomeItemDetailPage extends StatelessWidget {
  const HomeItemDetailPage({
    super.key,
    @PathParam('id') required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<HomeItemDetailCubit>()..loadItem(id),
      child: BlocBuilder<HomeItemDetailCubit, HomeItemDetailState>(
        builder: (context, state) => switch (state) {
          HomeItemDetailFailure(:final message) => DsError(
              message: message,
              retryLabel: 'Retry',
              onRetry: () =>
                  context.read<HomeItemDetailCubit>().loadItem(id),
            ),
          _ => _DetailScaffold(state: state),
        },
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.state});

  final HomeItemDetailState state;

  @override
  Widget build(BuildContext context) {
    final item = state is HomeItemDetailLoaded
        ? (state as HomeItemDetailLoaded).item
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(item?.title ?? '')),
      body: item == null
          ? const DsLoading()
          : _DetailBody(item: item),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (item.imageUrl != null)
          ClipRRect(
            borderRadius: AppRadius.borderRadiusMd,
            child: Image.network(
              item.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (item.imageUrl != null) const SizedBox(height: AppSpacing.md),
        if (item.isFeatured)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: const Text('Featured'),
                avatar: const Icon(Icons.star, size: 16),
                backgroundColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        Text(
          item.title,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          item.description,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
