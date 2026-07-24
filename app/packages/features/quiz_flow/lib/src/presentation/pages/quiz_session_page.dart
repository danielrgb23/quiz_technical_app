import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../../routes/quiz_flow_routes.dart';
import '../cubit/quiz_session_cubit.dart';
import '../cubit/quiz_session_state.dart';

/// Sessão de quiz: questão → feedback → resumo (spec-03). Cobre os modos
/// topic (via pré-sessão), review e daily (deeplink `/daily`).
@RoutePage()
class QuizSessionPage extends StatefulWidget {
  const QuizSessionPage({
    required this.mode,
    this.topic,
    this.size = 10,
    super.key,
  });

  final SessionMode mode;
  final String? topic;
  final int size;

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionCubit _cubit;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<QuizSessionCubit>()
      ..start(mode: widget.mode, topic: widget.topic, size: widget.size);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<bool> _confirmAbandon(BuildContext context) async {
    final l10n = QuizLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.abandonDialogTitle),
        content: Text(l10n.abandonDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.abandonCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.abandonConfirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return BlocProvider.value(
      value: _cubit,
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final state = _cubit.state;
          final isTerminal =
              state is QuizSessionSummary ||
              state is QuizSessionEmpty ||
              state is QuizSessionError;
          final shouldPop = isTerminal ? true : await _confirmAbandon(context);
          if (shouldPop && context.mounted) {
            setState(() => _allowPop = true);
            await context.router.maybePop();
          }
        },
        child: Scaffold(
          body: BlocBuilder<QuizSessionCubit, QuizSessionState>(
            builder: (context, state) => switch (state) {
              QuizSessionLoading() => const DsLoading(),
              QuizSessionEmpty() => _EmptyView(
                message: l10n.emptyReviewMessage,
              ),
              QuizSessionQuestion() => _QuestionView(
                state: state,
                cubit: _cubit,
              ),
              QuizSessionFeedback() => _FeedbackView(
                state: state,
                cubit: _cubit,
              ),
              QuizSessionSummary(result: final result) => _SummaryView(
                result: result,
                mode: widget.mode,
                topic: widget.topic,
                size: widget.size,
              ),
              QuizSessionError(message: final message) => DsError(
                message: message,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state, required this.cubit});

  final QuizSessionQuestion state;
  final QuizSessionCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (state.index) / state.total,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 18),
                    const SizedBox(width: 4),
                    Text('${state.streakDays}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.questionProgressLabel(state.index + 1, state.total),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuestionBody(question: state.current),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.separated(
                itemCount: state.current.options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _AlternativeCard(
                  text: state.current.options[index],
                  selected: state.selectedIndex == index,
                  onTap: () => cubit.selectOption(index),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: DsButton(
                label: l10n.confirmButtonLabel,
                onPressed: state.selectedIndex == null ? null : cubit.confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.state, required this.cubit});

  final QuizSessionFeedback state;
  final QuizSessionCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final isCorrect = state.answer.isCorrect;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.questionProgressLabel(state.index + 1, state.total),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuestionBody(question: state.current),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < state.current.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AlternativeCard(
                        text: state.current.options[i],
                        selected: i == state.answer.selectedIndex,
                        correct: i == state.current.correctIndex,
                        revealed: true,
                        onTap: null,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.explanationLabel,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(state.current.explanation),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await cubit.reportCurrentQuestion();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.reportSuccessMessage)),
                        );
                      }
                    },
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: Text(l10n.reportButtonLabel),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: DsButton(
                label: l10n.understoodButtonLabel,
                onPressed: cubit.acknowledgeFeedback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.result,
    required this.mode,
    required this.topic,
    required this.size,
  });

  final SessionResult result;
  final SessionMode mode;
  final String? topic;
  final int size;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.summaryScoreLabel(
                result.correctCount,
                result.totalQuestions,
              ),
            ),
            Text(l10n.xpEarnedLabel(result.xpEarned)),
            Text(l10n.streakLabel(result.streakDays)),
            if (result.wrongAnswers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.wrongAnswersTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    for (final answer in result.wrongAnswers)
                      ListTile(
                        leading: const Icon(Icons.close, color: Colors.red),
                        title: Text(answer.questionId),
                      ),
                  ],
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: DsButton(
                label: l10n.newSessionButtonLabel,
                onPressed: () => context.router.replace(
                  QuizSessionRoute(mode: mode, topic: topic, size: size),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final looksLikeCode = question.question.contains('```');
    return Text(
      question.question,
      style: looksLikeCode
          ? const TextStyle(fontFamily: 'monospace')
          : Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.text,
    required this.selected,
    required this.onTap,
    this.correct,
    this.revealed = false,
  });

  final String text;
  final bool selected;
  final bool? correct;
  final bool revealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (revealed) {
      if (correct == true) {
        color = Colors.green.withValues(alpha: 0.15);
      } else if (selected && correct == false) {
        color = Colors.red.withValues(alpha: 0.15);
      }
    } else if (selected) {
      color = Theme.of(context).colorScheme.primaryContainer;
    }

    return DsCard(
      onTap: onTap,
      child: Container(
        color: color,
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (revealed && correct == true)
              const Icon(Icons.check, color: Colors.green),
            if (revealed && selected && correct == false)
              const Icon(Icons.close, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
