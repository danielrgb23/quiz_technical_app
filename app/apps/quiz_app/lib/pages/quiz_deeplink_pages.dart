import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:question_bank_module/question_bank.dart';

import '../di/injection.dart';
import '../l10n/generated/app_localizations.dart';

/// Telas-alvo dos deeplinks (Spec 02). São placeholders navegáveis com o
/// guard de conteúdo; a Spec 03 substitui pelo fluxo real de quiz.
@RoutePage()
class QuizTopicPage extends StatelessWidget {
  const QuizTopicPage({@PathParam('topic') required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ContentGuard<List<Question>>(
      title: l10n.quizTopicTitle(topic),
      load: () async {
        final result = await getIt<QuestionRepository>().getByTopic(topic);
        final questions = result.dataOrNull ?? const [];
        return questions.isEmpty ? null : questions;
      },
      builder: (context, questions) => ListView(
        children: [
          for (final q in questions)
            ListTile(
              title: Text(q.question),
              subtitle: Text(l10n.questionLevelLabel(q.level)),
            ),
        ],
      ),
    );
  }
}

@RoutePage()
class QuestionDetailPage extends StatelessWidget {
  const QuestionDetailPage({@PathParam('id') required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ContentGuard<Question>(
      title: l10n.questionPageTitle,
      load: () async =>
          (await getIt<QuestionRepository>().getById(id)).dataOrNull,
      builder: (context, question) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $option'),
              ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class DailyChallengePage extends StatelessWidget {
  const DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ContentGuard<List<Question>>(
      title: l10n.dailyChallengeTitle,
      load: () async {
        final result = await getIt<QuestionRepository>().getAll();
        final questions = result.dataOrNull ?? const [];
        return questions.isEmpty ? null : questions.take(10).toList();
      },
      builder: (context, questions) => ListView(
        children: [
          for (final q in questions) ListTile(title: Text(q.question)),
        ],
      ),
    );
  }
}

/// Guard de conteúdo: carrega dados locais; se indisponíveis, mostra
/// tela de fallback com CTA em vez de erro.
class _ContentGuard<T> extends StatelessWidget {
  const _ContentGuard({
    required this.title,
    required this.load,
    required this.builder,
  });

  final String title;
  final Future<T?> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<T?>(
        future: load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.contentUnavailableMessage),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.router.replaceAll([const HomeRouteRef()]),
                    child: Text(l10n.goHomeButtonLabel),
                  ),
                ],
              ),
            );
          }
          return builder(context, data);
        },
      ),
    );
  }
}

/// Referência indireta à rota inicial sem acoplar no arquivo gerado.
class HomeRouteRef extends PageRouteInfo<void> {
  const HomeRouteRef() : super('HomeRoute');
}
