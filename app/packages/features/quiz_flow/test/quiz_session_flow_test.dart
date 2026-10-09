import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quiz_flow/quiz_flow.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:shared/shared.dart' show FakeSoundService, SoundService;

import 'fakes.dart';

/// Smoke test do fluxo: questão → erro → explicação → resumo (spec-03,
/// meta de teste widget da task 2.11).
void main() {
  setUp(() {
    final questionRepo = FakeQuestionRepository([makeQuestion('f1')]);
    final progressRepo = FakeProgressRepository();
    final localStorage = FakeLocalStorage();

    GetIt.I.registerSingleton<SoundService>(FakeSoundService());
    GetIt.I.registerFactory<QuizSessionCubit>(
      () => QuizSessionCubit(
        StartSessionUseCase(questionRepo, progressRepo),
        AnswerQuestionUseCase(progressRepo, SpacedRepetitionScheduler()),
        CompleteSessionUseCase(
          localStorage,
          StreakService(),
          FakeStatsSyncGateway(),
        ),
        GetUserStatsUseCase(
          localStorage,
          questionRepo,
          progressRepo,
          StreakService(),
        ),
        FakeQuestionReportRepository(),
        FakeAnalyticsService(),
        LearningPathService(questionRepo, localStorage),
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
    // O CTA do card pulsa para sempre: pumpAndSettle nunca assenta no feedback.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Feedback: card mostra a questão na frente; toca para virar e ver a
    // explicação no verso.
    expect(find.byType(DsFlipCard), findsOneWidget);
    await tester.tap(find.text(l10n.flipCtaSeeExplanation));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text(l10n.flipCtaBackToQuestion), findsOneWidget);
    expect(
      find.text('A alternativa certa está correta porque sim.'),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.understoodButtonLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    // Resumo da sessão.
    expect(find.text(l10n.summaryDoneTitle), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
    expect(find.text('${l10n.summaryReviewTitle} (1)'), findsOneWidget);
    expect(find.text(l10n.summaryFinish), findsOneWidget);
  });
}
