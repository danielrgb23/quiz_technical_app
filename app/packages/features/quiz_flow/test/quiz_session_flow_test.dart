import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quiz_flow/quiz_flow.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

/// Smoke test do fluxo: questão → erro → explicação → resumo (spec-03,
/// meta de teste widget da task 2.11).
void main() {
  setUp(() {
    final questionRepo = FakeQuestionRepository([makeQuestion('f1')]);
    final progressRepo = FakeProgressRepository();
    final localStorage = FakeLocalStorage();

    GetIt.I.registerFactory<QuizSessionCubit>(
      () => QuizSessionCubit(
        StartSessionUseCase(questionRepo, progressRepo),
        AnswerQuestionUseCase(progressRepo, SpacedRepetitionScheduler()),
        CompleteSessionUseCase(localStorage, StreakService()),
        GetUserStatsUseCase(localStorage, questionRepo, progressRepo),
        FakeQuestionReportRepository(),
        FakeAnalyticsService(),
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('questão errada mostra explicação e leva ao resumo', (
    tester,
  ) async {
    final l10n = await QuizLocalizations.delegate.load(const Locale('pt'));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        supportedLocales: QuizLocalizations.supportedLocales,
        localizationsDelegates: [
          QuizLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: QuizSessionPage(
          mode: SessionMode.topic,
          topic: 'flutter',
          size: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tela de questão: seleciona uma alternativa errada.
    expect(find.text('Pergunta f1?'), findsOneWidget);
    await tester.tap(find.text('errada 1'));
    await tester.pump();
    await tester.tap(find.text(l10n.confirmButtonLabel));
    await tester.pumpAndSettle();

    // Feedback: card mostra a questão na frente; toca para virar e ver a
    // explicação no verso.
    expect(find.byType(DsFlipCard), findsOneWidget);
    await tester.tap(find.byType(DsFlipCard));
    await tester.pumpAndSettle();

    expect(find.text(l10n.explanationLabel), findsOneWidget);
    expect(
      find.text('A alternativa certa está correta porque sim.'),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.understoodButtonLabel));
    await tester.pumpAndSettle();

    // Resumo da sessão.
    expect(find.text(l10n.summaryTitle), findsOneWidget);
    expect(find.text(l10n.summaryScoreLabel(0, 1)), findsOneWidget);
  });
}
