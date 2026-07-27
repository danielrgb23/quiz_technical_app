import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../cubit/single_question_cubit.dart';
import '../cubit/single_question_state.dart';

/// Modo questão única (deeplink `/question/{id}`): a explicação fica
/// sempre visível ao responder, independente do resultado.
@RoutePage()
class SingleQuestionPage extends StatefulWidget {
  const SingleQuestionPage({@PathParam('id') required this.id, super.key});

  final String id;

  @override
  State<SingleQuestionPage> createState() => _SingleQuestionPageState();
}

class _SingleQuestionPageState extends State<SingleQuestionPage> {
  late final SingleQuestionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<SingleQuestionCubit>()..load(widget.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.questionPageTitle)),
        body: BlocBuilder<SingleQuestionCubit, SingleQuestionState>(
          builder: (context, state) => switch (state) {
            SingleQuestionLoading() => const DsLoading(),
            SingleQuestionNotFound() => Center(
              child: Text(l10n.questionNotFoundMessage),
            ),
            SingleQuestionError(message: final message) => Center(
              child: Text(message),
            ),
            SingleQuestionLoaded() => _LoadedView(state: state, cubit: _cubit),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatefulWidget {
  const _LoadedView({required this.state, required this.cubit});

  final SingleQuestionLoaded state;
  final SingleQuestionCubit cubit;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final state = widget.state;
    final cubit = widget.cubit;
    final answer = state.answer;

    if (answer == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.question.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: state.question.options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final color = state.selectedIndex == index
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null;
                    return DsCard(
                      onTap: () => cubit.selectOption(index),
                      child: Container(
                        color: color,
                        child: Text(state.question.options[index]),
                      ),
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

    final isCorrect = answer.selectedIndex == state.question.correctIndex;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DsFlipCard(
                showBack: _showBack,
                onFlip: (showBack) => setState(() => _showBack = showBack),
                front: _SingleQuestionFace(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.question.question,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (
                          var i = 0;
                          i < state.question.options.length;
                          i++
                        )
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _AnswerOption(
                              text: state.question.options[i],
                              selected: i == answer.selectedIndex,
                              correct: i == state.question.correctIndex,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        _SingleQuestionHint(
                          icon: Icons.flip,
                          label: l10n.flipToExplanationHint,
                        ),
                      ],
                    ),
                  ),
                ),
                back: _SingleQuestionFace(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.error.withValues(alpha: 0.06),
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
                          state.question.explanation,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SingleQuestionHint(
                          icon: Icons.flip_camera_android_outlined,
                          label: l10n.flipToQuestionHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.correct,
  });

  final String text;
  final bool selected;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (correct) {
      color = AppColors.success.withValues(alpha: 0.15);
    } else if (selected) {
      color = AppColors.error.withValues(alpha: 0.15);
    }
    return DsCard(
      child: Container(
        color: color,
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (correct) const Icon(Icons.check, color: AppColors.success),
            if (selected && !correct)
              const Icon(Icons.close, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _SingleQuestionFace extends StatelessWidget {
  const _SingleQuestionFace({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusLg),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

class _SingleQuestionHint extends StatelessWidget {
  const _SingleQuestionHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
