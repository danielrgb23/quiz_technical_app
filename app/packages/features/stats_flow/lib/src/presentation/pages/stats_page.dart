import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/stats_localizations.dart';
import '../cubit/stats_cubit.dart';
import '../cubit/stats_state.dart';

/// Tela de estatísticas (features/stats_flow, spec-03): streak, XP,
/// desempenho por tópico, questões mais erradas.
@RoutePage()
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final StatsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<StatsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StatsLocalizations.of(context)!;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.statsTitle)),
        body: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) => switch (state) {
            StatsLoading() => const DsLoading(),
            StatsError(message: final message) => DsError(
              message: message,
              onRetry: _cubit.load,
            ),
            StatsLoaded(stats: final stats) => _StatsView(
              stats: stats,
              l10n: l10n,
            ),
          },
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats, required this.l10n});

  final UserStats stats;
  final StatsLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (stats.byTopic.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(l10n.emptyStatsMessage, textAlign: TextAlign.center),
        ),
      );
    }

    final mostWrong = [...stats.byTopic]
      ..sort((a, b) => b.wrong.compareTo(a.wrong));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: DsCard(
                child: Column(
                  children: [
                    const Icon(Icons.local_fire_department),
                    Text(l10n.streakLabel(stats.streakDays)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DsCard(
                child: Column(
                  children: [
                    const Icon(Icons.star),
                    Text(l10n.xpTotalLabel(stats.xpTotal)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.byTopicTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final topic in mostWrong)
          DsCard(
            child: ListTile(
              title: Text(topic.topic),
              subtitle: Text(
                l10n.topicStatsLabel(topic.seen, topic.correct, topic.wrong),
              ),
            ),
          ),
      ],
    );
  }
}
