import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../l10n/generated/home_localizations.dart';
import '../bloc/home_cubit.dart';

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
            icon: const Icon(Icons.person),
            onPressed: () => context.router.pushPath(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.router.pushPath(AppRoutes.stats),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'onboarding':
                  context.router.pushPath(AppRoutes.onboarding);
                  break;
                case 'login':
                  context.router.pushPath(AppRoutes.login);
                  break;
                case 'register':
                  context.router.pushPath(AppRoutes.register);
                  break;
                case 'logout':
                  context.router.pushPath(AppRoutes.login);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'onboarding',
                child: Text(l10n.navOnboarding),
              ),
              PopupMenuItem(value: 'login', child: Text(l10n.navLogin)),
              PopupMenuItem(value: 'register', child: Text(l10n.navRegister)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text(l10n.navLogout)),
            ],
          ),
        ],
      ),
      body: switch (state) {
        HomeInitial() || HomeLoading() => const DsLoading(),
        HomeLoaded(:final topics, :final streakDays) => _DashboardBody(
          topics: topics,
          streakDays: streakDays,
          l10n: l10n,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.topics,
    required this.streakDays,
    required this.l10n,
  });

  final List<String> topics;
  final int streakDays;
  final HomeLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        DsCard(
          child: Row(
            children: [
              const Icon(Icons.local_fire_department),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.streakLabel(streakDays)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: DsButton(
            label: l10n.dailyChallengeCta,
            icon: Icons.today,
            onPressed: () => context.router.pushPath(AppRoutes.daily),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: DsButton(
            label: l10n.reviewCta,
            icon: Icons.refresh,
            onPressed: () => context.router.pushPath(AppRoutes.review),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.topicsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (topics.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Center(child: Text(l10n.noTopicsMessage)),
          )
        else
          for (final topic in topics)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DsCard(
                onTap: () =>
                    context.router.pushPath(AppRoutes.quizTopicPath(topic)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(topic), const Icon(Icons.chevron_right)],
                ),
              ),
            ),
      ],
    );
  }
}
