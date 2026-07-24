import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:stats_flow/stats_flow.dart';

void main() {
  tearDown(() async => GetIt.I.reset());

  testWidgets('exibe streak, XP e desempenho por tópico', (tester) async {
    GetIt.I.registerFactory<StatsCubit>(
      () => StatsCubit(_StubGetUserStatsUseCase()),
    );

    final l10n = await StatsLocalizations.delegate.load(const Locale('pt'));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        supportedLocales: StatsLocalizations.supportedLocales,
        localizationsDelegates: [
          StatsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StatsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.streakLabel(5)), findsOneWidget);
    expect(find.text(l10n.xpTotalLabel(120)), findsOneWidget);
    expect(find.text('flutter'), findsOneWidget);
  });
}

class _StubGetUserStatsUseCase implements GetUserStatsUseCase {
  @override
  Future<Result<UserStats>> call() async => Result.success(
    const UserStats(
      streakDays: 5,
      xpTotal: 120,
      byTopic: [TopicStats(topic: 'flutter', seen: 4, correct: 3, wrong: 1)],
    ),
  );
}
