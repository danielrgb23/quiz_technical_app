import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:shared/shared.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../cubit/quiz_session_cubit.dart';
import '../cubit/quiz_session_state.dart';
import '../widgets/lesson_summary_view.dart';

/// Sessão de quiz: questão → feedback → resumo (spec-03). Cobre os modos
/// topic (via pré-sessão), review e daily (deeplink `/daily`).
@RoutePage()
class QuizSessionPage extends StatefulWidget {
  const QuizSessionPage({
    required this.mode,
    this.topic,
    this.size = 10,
    this.lesson,
    super.key,
  });

  final SessionMode mode;
  final String? topic;
  final int size;

  /// Índice da lição na trilha do tópico (só no modo topic).
  final int? lesson;

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late final QuizSessionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<QuizSessionCubit>()
      ..start(
        mode: widget.mode,
        topic: widget.topic,
        size: widget.size,
        lesson: widget.lesson,
      );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _restart() => _cubit.start(
    mode: widget.mode,
    topic: widget.topic,
    size: widget.size,
    lesson: widget.lesson,
  );

  void _playSoundFor(QuizSessionState state) {
    final sound = GetIt.I<SoundService>();
    switch (state) {
      case QuizSessionFeedback(:final answer):
        unawaited(sound.play(answer.isCorrect ? Sfx.correct : Sfx.wrong));
      case QuizSessionSummary(:final lesson):
        unawaited(
          sound.play(
            lesson == null || lesson.passed ? Sfx.complete : Sfx.wrong,
          ),
        );
      default:
        break;
    }
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

  Future<void> _handleBackPressed(BuildContext context) async {
    final state = _cubit.state;
    final isTerminal =
        state is QuizSessionSummary ||
        state is QuizSessionEmpty ||
        state is QuizSessionError;
    final shouldPop = isTerminal ? true : await _confirmAbandon(context);
    // Unconditional pop: bypasses PopScope's canPop guard, which we keep
    // permanently false so the system back gesture always routes through
    // this confirmation flow. Using router.maybePop() here would re-check
    // canPop and get blocked again, requiring a second tap to actually pop.
    if (shouldPop && context.mounted) {
      context.router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return BlocProvider.value(
      value: _cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleBackPressed(context);
        },
        child: Scaffold(
          body: BlocConsumer<QuizSessionCubit, QuizSessionState>(
            listenWhen: (prev, next) => prev.runtimeType != next.runtimeType,
            listener: (context, state) => _playSoundFor(state),
            builder: (context, state) => switch (state) {
              QuizSessionLoading() => const DsLoading(),
              QuizSessionEmpty() => _EmptyView(
                message: l10n.emptyReviewMessage,
              ),
              QuizSessionQuestion() => _QuestionView(
                state: state,
                cubit: _cubit,
                onBack: () => _handleBackPressed(context),
              ),
              QuizSessionFeedback() => _FeedbackView(
                state: state,
                cubit: _cubit,
                onBack: () => _handleBackPressed(context),
              ),
              QuizSessionSummary() => LessonSummaryView(
                summary: state,
                onPrimary: () => switch (state.lesson) {
                  null => context.router.popUntilRoot(),
                  LessonOutcome(passed: true) => context.router.pop(),
                  _ => _restart(),
                },
                onSecondary: () => context.router.pop(),
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
  const _QuestionView({
    required this.state,
    required this.cubit,
    required this.onBack,
  });

  final QuizSessionQuestion state;
  final QuizSessionCubit cubit;
  final VoidCallback onBack;

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
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                itemCount: state.optionOrder.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, position) {
                  final optionIndex = state.optionOrder[position];
                  return _AlternativeCard(
                    text: state.current.options[optionIndex],
                    selected: state.selectedIndex == optionIndex,
                    onTap: () {
                      unawaited(GetIt.I<SoundService>().play(Sfx.tap));
                      cubit.selectOption(optionIndex);
                    },
                  );
                },
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

class _FeedbackView extends StatefulWidget {
  const _FeedbackView({
    required this.state,
    required this.cubit,
    required this.onBack,
  });

  final QuizSessionFeedback state;
  final QuizSessionCubit cubit;
  final VoidCallback onBack;

  @override
  State<_FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<_FeedbackView> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final state = widget.state;
    final cubit = widget.cubit;
    final isCorrect = state.answer.isCorrect;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.questionProgressLabel(state.index + 1, state.total),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _FlipTabs(
              showBack: _showBack,
              questionLabel: l10n.flipTabQuestion,
              explanationLabel: l10n.flipTabExplanation,
              onChanged: (showBack) => setState(() => _showBack = showBack),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: DsFlipCard(
                key: ValueKey(state.current.id),
                peek: true,
                showBack: _showBack,
                onFlip: (showBack) => setState(() => _showBack = showBack),
                front: _FlashCardFace(
                  cta: _FlipCta(
                    icon: Icons.touch_app_rounded,
                    label: l10n.flipCtaSeeExplanation,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _QuestionBody(question: state.current),
                        const SizedBox(height: AppSpacing.lg),
                        for (final i in state.optionOrder)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _AlternativeCard(
                              text: state.current.options[i],
                              selected: i == state.answer.selectedIndex,
                              correct: i == state.current.correctIndex,
                              revealed: true,
                              onTap: null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                back: _FlashCardFace(
                  cta: _FlipCta(
                    icon: Icons.flip_camera_android_rounded,
                    label: l10n.flipCtaBackToQuestion,
                  ),
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.18)
                      : AppColors.error.withValues(alpha: 0.10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.explanationLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.current.explanation,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
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

class _FlashCardFace extends StatelessWidget {
  const _FlashCardFace({required this.child, required this.cta, this.color});

  final Widget child;

  /// Botão-dica fixo na base do card ("toque para virar").
  final Widget cta;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusLg,
          side: BorderSide(
            color: AppColors.primaryVariant.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Expanded(child: child),
              const SizedBox(height: AppSpacing.sm),
              cta,
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa fixa no rodapé do card que deixa claro que ele gira ao toque.
class _FlipCta extends StatefulWidget {
  const _FlipCta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  State<_FlipCta> createState() => _FlipCtaState();
}

class _FlipCtaState extends State<_FlipCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.025 * Curves.easeInOut.transform(_pulse.value),
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.35),
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(color: AppColors.primaryVariant, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: AppColors.onPrimary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.sync_rounded, color: AppColors.onPrimary),
          ],
        ),
      ),
    );
  }
}

/// Alternador "Pergunta | Explicação" acima do card: segundo caminho,
/// explícito, para virar o card.
class _FlipTabs extends StatelessWidget {
  const _FlipTabs({
    required this.showBack,
    required this.questionLabel,
    required this.explanationLabel,
    required this.onChanged,
  });

  final bool showBack;
  final String questionLabel;
  final String explanationLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          _tab(
            context,
            questionLabel,
            Icons.help_outline_rounded,
            !showBack,
            () => onChanged(false),
          ),
          _tab(
            context,
            explanationLabel,
            Icons.lightbulb_outline_rounded,
            showBack,
            () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
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
        color = AppColors.success.withValues(alpha: 0.3);
      } else if (selected && correct == false) {
        color = AppColors.error.withValues(alpha: 0.18);
      }
    } else if (selected) {
      color = Theme.of(context).colorScheme.primaryContainer;
    }

    return DsCard(
      onTap: onTap,
      color: color,
      child: Row(
        children: [
          Expanded(child: Text(text)),
          if (revealed && correct == true)
            const Icon(Icons.check, color: AppColors.successDark),
          if (revealed && selected && correct == false)
            const Icon(Icons.close, color: AppColors.error),
        ],
      ),
    );
  }
}
