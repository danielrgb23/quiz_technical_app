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

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state, required this.cubit});

  final SingleQuestionLoaded state;
  final SingleQuestionCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final answer = state.answer;
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
                  final revealed = answer != null;
                  final isCorrectOption = index == state.question.correctIndex;
                  Color? color;
                  if (revealed) {
                    if (isCorrectOption) {
                      color = Colors.green.withValues(alpha: 0.15);
                    } else if (index == answer.selectedIndex) {
                      color = Colors.red.withValues(alpha: 0.15);
                    }
                  } else if (state.selectedIndex == index) {
                    color = Theme.of(context).colorScheme.primaryContainer;
                  }
                  return DsCard(
                    onTap: revealed ? null : () => cubit.selectOption(index),
                    child: Container(
                      color: color,
                      child: Text(state.question.options[index]),
                    ),
                  );
                },
              ),
            ),
            if (answer != null) ...[
              DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.explanationLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(state.question.explanation),
                  ],
                ),
              ),
            ] else
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
