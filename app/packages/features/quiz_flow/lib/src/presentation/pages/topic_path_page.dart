import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../../routes/quiz_flow_routes.dart';
import '../cubit/topic_path_cubit.dart';

const _nodeSize = 76.0;
const _nodeGap = 28.0;
const _pathAmplitude = 72.0;

/// Trilha do tópico (deeplink `/quiz/{topic}`), no estilo do Duolingo:
/// cabeçalho da unidade + nós circulares em zigue-zague (concluído / atual /
/// bloqueado). Cada nó é uma lição de [lessonSize] questões e só libera a
/// próxima com >= 80% de acertos.
@RoutePage()
class TopicPathPage extends StatefulWidget {
  const TopicPathPage({@PathParam('topic') required this.topic, super.key});

  final String topic;

  @override
  State<TopicPathPage> createState() => _TopicPathPageState();
}

class _TopicPathPageState extends State<TopicPathPage> {
  late final TopicPathCubit _cubit;
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<TopicPathCubit>()..load(widget.topic);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _startLesson(int lesson) async {
    unawaited(GetIt.I<SoundService>().play(Sfx.start));
    await context.router.push(
      QuizSessionRoute(
        mode: SessionMode.topic,
        topic: widget.topic,
        size: lessonSize,
        lesson: lesson,
      ),
    );
    if (mounted) await _cubit.load(widget.topic);
  }

  void _onLocked() {
    unawaited(GetIt.I<SoundService>().play(Sfx.locked));
    final l10n = QuizLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.pathLockedMessage((lessonPassRatio * 100).round()),
          ),
        ),
      );
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx != null) {
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final color = topicColor(widget.topic);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(prettyTopic(widget.topic))),
        body: SafeArea(
          top: false,
          child: BlocConsumer<TopicPathCubit, TopicPathState>(
            listenWhen: (prev, next) => next is TopicPathLoaded,
            listener: (_, _) => _scrollToCurrent(),
            builder: (context, state) => switch (state) {
              TopicPathLoading() => const DsLoading(),
              TopicPathError() => DsError(
                message: l10n.pathLoadError,
                retryLabel: l10n.pathRetry,
                onRetry: () => _cubit.load(widget.topic),
              ),
              TopicPathLoaded() when state.totalLessons == 0 => Center(
                child: Text(l10n.pathEmptyMessage),
              ),
              TopicPathLoaded() => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  _UnitHeader(
                    topic: widget.topic,
                    color: color,
                    completed: state.completedLessons,
                    total: state.totalLessons,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (var i = 0; i < state.totalLessons; i++)
                    _PathStep(
                      key: i == state.completedLessons ? _currentKey : null,
                      index: i,
                      status: i < state.completedLessons
                          ? _NodeStatus.done
                          : i == state.completedLessons
                          ? _NodeStatus.current
                          : _NodeStatus.locked,
                      isLast: i == state.totalLessons - 1,
                      color: color,
                      onTap: i <= state.completedLessons
                          ? () => _startLesson(i)
                          : _onLocked,
                    ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// Tópico `state_management` → `State management`.
String prettyTopic(String topic) {
  final text = topic.replaceAll('_', ' ');
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// Cor pastel estável por tópico (mesma ideia da lista da Home).
Color topicColor(String topic) {
  const palette = [
    AppColors.primaryVariant,
    AppColors.secondaryVariant,
    AppColors.xpDark,
    AppColors.lilac,
    AppColors.rose,
    AppColors.sky,
  ];
  return palette[topic.codeUnits.fold<int>(0, (a, b) => a + b) %
      palette.length];
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({
    required this.topic,
    required this.color,
    required this.completed,
    required this.total,
  });

  final String topic;
  final Color color;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : AppColors.onPrimary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(Colors.black26, color),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pathUnitLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor.withValues(alpha: 0.75),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            prettyTopic(topic),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.borderRadiusSm,
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(textColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.pathLessonsProgress(completed, total),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeStatus { done, current, locked }

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.index,
    required this.status,
    required this.isLast,
    required this.color,
    required this.onTap,
    super.key,
  });

  final int index;
  final _NodeStatus status;
  final bool isLast;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(index * math.pi / 2.2) * _pathAmplitude;
    final isCurrent = status == _NodeStatus.current;
    return Padding(
      padding: EdgeInsets.only(
        bottom: _nodeGap,
        top: isCurrent ? 36 : 0, // espaço para a bolha "COMEÇAR"
      ),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _PathNode(
                status: status,
                isTrophy: isLast,
                color: color,
                semanticLabel: QuizLocalizations.of(
                  context,
                )!.pathLessonSemantics(index + 1),
                onTap: onTap,
              ),
              if (isCurrent)
                Positioned(
                  top: -42,
                  child: _StartBubble(
                    label: QuizLocalizations.of(context)!.pathStartBubble,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathNode extends StatefulWidget {
  const _PathNode({
    required this.status,
    required this.isTrophy,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final _NodeStatus status;
  final bool isTrophy;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<_PathNode> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (face, icon, iconColor) = switch (widget.status) {
      _NodeStatus.done => (
        AppColors.xp,
        Icons.check_rounded,
        AppColors.onPrimary,
      ),
      _NodeStatus.current => (
        widget.color,
        widget.isTrophy ? Icons.emoji_events_rounded : Icons.star_rounded,
        ThemeData.estimateBrightnessForColor(widget.color) == Brightness.dark
            ? Colors.white
            : AppColors.onPrimary,
      ),
      _NodeStatus.locked => (
        AppColors.grey200,
        widget.isTrophy ? Icons.emoji_events_rounded : Icons.lock_rounded,
        AppColors.grey500,
      ),
    };
    final edge = Color.alphaBlend(Colors.black26, face);
    const depth = 7.0;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: SizedBox(
          width: _nodeSize,
          height: _nodeSize + depth,
          child: Stack(
            children: [
              // "Borda" 3D sólida sob o nó.
              Positioned(
                top: depth,
                child: Container(
                  width: _nodeSize,
                  height: _nodeSize,
                  decoration: BoxDecoration(
                    color: edge,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                top: _pressed ? depth : 0,
                child: Container(
                  width: _nodeSize,
                  height: _nodeSize,
                  decoration: BoxDecoration(
                    color: face,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartBubble extends StatefulWidget {
  const _StartBubble({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  State<_StartBubble> createState() => _StartBubbleState();
}

class _StartBubbleState extends State<_StartBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = Color.alphaBlend(Colors.black26, widget.color);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(color: border, width: 2),
            ),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Color.alphaBlend(Colors.black38, widget.color),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(16, 8),
            painter: _BubbleTailPainter(
              fill: Theme.of(context).colorScheme.surface,
              stroke: border,
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) =>
      old.fill != fill || old.stroke != stroke;
}
