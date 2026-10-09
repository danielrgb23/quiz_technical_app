import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/home_localizations.dart';
import '../bloc/home_cubit.dart';

const _xpPerLevel = 100;

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<HomeCubit>()..loadDashboard(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state) {
          HomeFailure(:final message) => DsError(
            message: message,
            retryLabel: HomeLocalizations.of(context)!.retry,
            onRetry: () => context.read<HomeCubit>().loadDashboard(),
          ),
          _ => _HomeContent(state: state),
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = HomeLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.router.pushPath(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.router.pushPath(AppRoutes.stats),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          HomeInitial() || HomeLoading() => const DsLoading(),
          HomeLoaded(
            :final topics,
            :final streakDays,
            :final xpTotal,
            :final paths,
          ) =>
            _DashboardBody(
              topics: topics,
              paths: paths,
              streakDays: streakDays,
              xpTotal: xpTotal,
              l10n: l10n,
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.topics,
    required this.paths,
    required this.streakDays,
    required this.xpTotal,
    required this.l10n,
  });

  final List<String> topics;
  final Map<String, PathProgress> paths;
  final int streakDays;
  final int xpTotal;
  final HomeLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ProgressHero(streakDays: streakDays, xpTotal: xpTotal, l10n: l10n),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _GameCta(
                label: l10n.dailyChallengeCta,
                icon: Icons.today_rounded,
                color: AppColors.secondary,
                onTap: () => context.router.pushPath(AppRoutes.daily),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GameCta(
                label: l10n.reviewCta,
                icon: Icons.replay_circle_filled_rounded,
                color: AppColors.lilac,
                onTap: () => context.router.pushPath(AppRoutes.review),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.topicsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (topics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Center(child: Text(l10n.noTopicsMessage)),
          )
        else
          for (final (i, topic) in topics.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TopicCard(
                topic: topic,
                index: i,
                progress: paths[topic],
                l10n: l10n,
                onTap: () async {
                  await context.router.pushPath(AppRoutes.quizTopicPath(topic));
                  if (context.mounted) {
                    unawaited(context.read<HomeCubit>().loadDashboard());
                  }
                },
              ),
            ),
      ],
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.streakDays,
    required this.xpTotal,
    required this.l10n,
  });

  final int streakDays;
  final int xpTotal;
  final HomeLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final level = (xpTotal ~/ _xpPerLevel) + 1;
    final progress = (xpTotal % _xpPerLevel) / _xpPerLevel;
    final xpToNextLevel = _xpPerLevel - (xpTotal % _xpPerLevel);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusLg,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.streak, AppColors.xp],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBadge(
                icon: Icons.local_fire_department,
                label: l10n.streakLabel(streakDays),
              ),
              _StatBadge(icon: Icons.star, label: l10n.xpTotalLabel(xpTotal)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.levelLabel(level),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.xpToNextLevelLabel(xpToNextLevel),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.borderRadiusSm,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              valueColor: const AlwaysStoppedAnimation(AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onPrimary, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GameCta extends StatelessWidget {
  const _GameCta({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: AppRadius.borderRadiusLg,
      child: InkWell(
        borderRadius: AppRadius.borderRadiusLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.onPrimary, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _topicPalette = [
  AppColors.primaryVariant,
  AppColors.secondaryVariant,
  AppColors.xpDark,
  AppColors.lilac,
  AppColors.rose,
  AppColors.sky,
];

const _topicIcons = {
  'flutter': Icons.flutter_dash,
  'dart': Icons.code,
  'android': Icons.android,
  'ios': Icons.phone_iphone,
  'state_management': Icons.hub_outlined,
  'concurrency': Icons.sync_alt,
  'architecture': Icons.architecture,
  'system_design': Icons.account_tree_outlined,
  'performance': Icons.speed,
  'testing': Icons.fact_check_outlined,
};

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.index,
    required this.progress,
    required this.l10n,
    required this.onTap,
  });

  final String topic;
  final int index;
  final PathProgress? progress;
  final HomeLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _topicPalette[index % _topicPalette.length];
    final icon = _topicIcons[topic] ?? Icons.school_outlined;
    final progress = this.progress;
    final ratio = progress == null || progress.total == 0
        ? 0.0
        : progress.completed / progress.total;

    return DsCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (progress != null && progress.total > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.topicLessonsLabel(progress.completed, progress.total),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            progress?.isFinished ?? false
                ? Icons.emoji_events_rounded
                : Icons.chevron_right,
            color: progress?.isFinished ?? false ? AppColors.xpDark : null,
          ),
        ],
      ),
    );
  }
}
