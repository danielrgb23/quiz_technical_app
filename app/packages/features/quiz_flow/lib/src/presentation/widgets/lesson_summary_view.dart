import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../cubit/quiz_session_state.dart';

/// Tela de resultado da sessão: anel de precisão animado, mensagem de
/// aprovação (>= 80% libera a próxima lição), métricas e questões a revisar.
class LessonSummaryView extends StatelessWidget {
  const LessonSummaryView({
    required this.summary,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final QuizSessionSummary summary;

  /// "Continuar" / "Tentar novamente" / "Concluir".
  final VoidCallback onPrimary;

  /// "Voltar à trilha" (só em lições reprovadas).
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final result = summary.result;
    final lesson = summary.lesson;
    final ratio = result.totalQuestions == 0
        ? 0.0
        : result.correctCount / result.totalQuestions;
    final pct = (ratio * 100).round();
    final needed = (lessonPassRatio * 100).round();

    final isLesson = lesson != null;
    final passed = !isLesson || lesson.passed;
    final accent = passed ? AppColors.successDark : AppColors.streakDark;
    final tint = passed ? AppColors.success : AppColors.streak;

    final title = !isLesson
        ? l10n.summaryDoneTitle
        : passed
        ? l10n.summaryPassedTitle
        : l10n.summaryFailedTitle;
    final subtitle = !isLesson
        ? l10n.summaryDoneSubtitle(pct)
        : !passed
        ? l10n.summaryFailedSubtitle(needed)
        : lesson.newlyUnlocked
        ? l10n.summaryPassedSubtitle(pct)
        : l10n.summaryPassedRepeatSubtitle(pct);

    final primaryLabel = !isLesson
        ? l10n.summaryFinish
        : passed
        ? l10n.summaryContinue
        : l10n.summaryRetry;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _BottomFade(
              enabled: summary.wrongQuestions.length > 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    _ScoreRing(
                      ratio: ratio,
                      percent: pct,
                      caption: l10n.summaryAccuracyCaption,
                      color: tint,
                      textColor: accent,
                      showGoal: isLesson,
                      goalLabel: l10n.summaryGoalLabel(needed),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (isLesson && lesson.newlyUnlocked) ...[
                      const SizedBox(height: AppSpacing.md),
                      _UnlockedPill(label: l10n.summaryNextUnlocked),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.star_rounded,
                            color: AppColors.xp,
                            value: '+${result.xpEarned}',
                            label: l10n.summaryStatXp,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.check_circle_rounded,
                            color: AppColors.secondary,
                            value:
                                '${result.correctCount}/${result.totalQuestions}',
                            label: l10n.summaryStatCorrect,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.streak,
                            value: l10n.summaryStreakDays(result.streakDays),
                            label: l10n.summaryStatStreak,
                          ),
                        ),
                      ],
                    ),
                    if (summary.wrongQuestions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l10n.summaryReviewTitle} (${summary.wrongQuestions.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final question in summary.wrongQuestions)
                        _ReviewItem(question: question),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsButton(label: primaryLabel, onPressed: onPrimary),
                if (onSecondary != null && isLesson && !passed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  DsButton(
                    label: l10n.summaryBackToPath,
                    variant: DsButtonVariant.text,
                    onPressed: onSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.ratio,
    required this.percent,
    required this.caption,
    required this.color,
    required this.textColor,
    required this.showGoal,
    required this.goalLabel,
  });

  final double ratio;
  final int percent;
  final String caption;
  final Color color;
  final Color textColor;
  final bool showGoal;
  final String goalLabel;

  static const _size = 190.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(_size),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  track: Theme.of(context).brightness == Brightness.light
                      ? AppColors.grey200
                      : AppColors.grey800,
                  goal: showGoal ? lessonPassRatio : null,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(caption, style: Theme.of(context).textTheme.labelLarge),
                  if (showGoal)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        goalLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.goal,
  });

  final double progress;
  final Color color;
  final Color track;
  final double? goal;

  static const _stroke = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(_stroke / 2 + 4);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arc, 0, 2 * math.pi, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        base..color = color,
      );
    }

    final goal = this.goal;
    if (goal != null) {
      // Marca da meta (80%) cruzando o anel.
      final angle = -math.pi / 2 + 2 * math.pi * goal;
      final center = rect.center;
      final r = arc.width / 2;
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (r - 14);
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (r + 14);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppColors.onPrimary
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.goal != goal;
}

class _UnlockedPill extends StatelessWidget {
  const _UnlockedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_open_rounded,
              size: 18,
              color: AppColors.successDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.successDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onPrimary, size: 26),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.grey700),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  question.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esmaece a base da área rolável para sugerir que há mais conteúdo.
class _BottomFade extends StatelessWidget {
  const _BottomFade({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 36,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bg.withValues(alpha: 0), bg],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
