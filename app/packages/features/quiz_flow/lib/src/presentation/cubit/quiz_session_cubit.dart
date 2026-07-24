import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:shared/shared.dart';

import 'quiz_session_state.dart';

/// ViewModel da sessão de quiz (MVVM: estado imutável + métodos de intenção;
/// a View só conhece este Cubit).
@injectable
class QuizSessionCubit extends Cubit<QuizSessionState> {
  QuizSessionCubit(
    this._startSessionUseCase,
    this._answerQuestionUseCase,
    this._completeSessionUseCase,
    this._getUserStatsUseCase,
    this._questionReportRepository,
    this._analyticsService,
  ) : super(const QuizSessionState.loading());

  final StartSessionUseCase _startSessionUseCase;
  final AnswerQuestionUseCase _answerQuestionUseCase;
  final CompleteSessionUseCase _completeSessionUseCase;
  final GetUserStatsUseCase _getUserStatsUseCase;
  final QuestionReportRepository _questionReportRepository;
  final AnalyticsService _analyticsService;

  QuizSession? _session;
  int _streakDays = 0;
  DateTime? _questionStartedAt;

  QuizSession? get session => _session;

  Future<void> start({
    required SessionMode mode,
    String? topic,
    int size = 10,
  }) async {
    emit(const QuizSessionState.loading());

    final statsResult = await _getUserStatsUseCase();
    _streakDays = statsResult.dataOrNull?.streakDays ?? 0;

    final result = await _startSessionUseCase.call(
      mode: mode,
      topic: topic,
      size: size,
    );
    if (result.isFailure) {
      emit(QuizSessionState.error(result.failureOrNull!.message));
      return;
    }

    _session = result.dataOrNull!;
    if (_session!.questions.isEmpty) {
      emit(const QuizSessionState.empty());
      return;
    }

    unawaited(
      _analyticsService.logEvent(
        'session_started',
        parameters: {'mode': mode.name, if (topic != null) 'topic': topic},
      ),
    );
    _emitCurrentQuestion();
  }

  void selectOption(int index) {
    final current = state;
    if (current is! QuizSessionQuestion) return;
    emit(current.copyWith(selectedIndex: index));
  }

  Future<void> confirm() async {
    final current = state;
    final session = _session;
    if (current is! QuizSessionQuestion ||
        current.selectedIndex == null ||
        session == null) {
      return;
    }

    final elapsedMs = _questionStartedAt == null
        ? 0
        : DateTime.now().difference(_questionStartedAt!).inMilliseconds;

    final result = await _answerQuestionUseCase.call(
      question: current.current,
      selectedIndex: current.selectedIndex!,
      elapsedMs: elapsedMs,
    );
    if (result.isFailure) {
      emit(QuizSessionState.error(result.failureOrNull!.message));
      return;
    }

    final answer = result.dataOrNull!;
    _session = session.copyWith(answers: [...session.answers, answer]);

    unawaited(
      _analyticsService.logEvent(
        'question_answered',
        parameters: {
          'topic': current.current.topic,
          'level': current.current.level,
          'correct': answer.isCorrect,
          'elapsedMs': elapsedMs,
        },
      ),
    );

    emit(
      QuizSessionState.feedback(
        current: current.current,
        answer: answer,
        index: current.index,
        total: current.total,
      ),
    );
  }

  /// Chamado pelo botão "entendi" (erro) ou automaticamente após acerto.
  Future<void> acknowledgeFeedback() async {
    final session = _session;
    if (session == null) return;

    final nextSession = session.copyWith(
      currentIndex: session.currentIndex + 1,
    );
    _session = nextSession;

    if (nextSession.isFinished) {
      final result = await _completeSessionUseCase.call(nextSession);
      if (result.isFailure) {
        emit(QuizSessionState.error(result.failureOrNull!.message));
        return;
      }
      final sessionResult = result.dataOrNull!;
      unawaited(
        _analyticsService.logEvent(
          'session_completed',
          parameters: {
            'mode': nextSession.mode.name,
            'score': sessionResult.correctCount,
          },
        ),
      );
      if (sessionResult.streakDays > _streakDays) {
        unawaited(
          _analyticsService.logEvent(
            'streak_incremented',
            parameters: {'days': sessionResult.streakDays},
          ),
        );
      }
      emit(QuizSessionState.summary(sessionResult));
      return;
    }

    _emitCurrentQuestion();
  }

  /// Report de questão (botão discreto na tela de feedback).
  Future<void> reportCurrentQuestion() async {
    final current = state;
    if (current is! QuizSessionFeedback) return;

    await _questionReportRepository.reportQuestion(current.current.id);
    unawaited(
      _analyticsService.logEvent(
        'question_flagged',
        parameters: {'id': current.current.id},
      ),
    );
  }

  void _emitCurrentQuestion() {
    final session = _session!;
    _questionStartedAt = DateTime.now();
    emit(
      QuizSessionState.question(
        current: session.currentQuestion!,
        index: session.currentIndex,
        total: session.questions.length,
        streakDays: _streakDays,
      ),
    );
  }
}
