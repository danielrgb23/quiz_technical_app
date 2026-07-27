import 'dart:math';

import 'package:flutter/material.dart';

/// Card com animação de flip 3D no eixo Y. Toque para alternar entre [front]
/// e [back] — usado no flash card de explicação do quiz.
class DsFlipCard extends StatefulWidget {
  const DsFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 450),
    this.showBack = false,
    this.onFlip,
  });

  final Widget front;
  final Widget back;
  final Duration duration;

  /// Permite controlar o lado exibido de fora (ex.: resetar ao trocar de
  /// questão). Quando muda, a animação segue para o novo lado.
  final bool showBack;
  final ValueChanged<bool>? onFlip;

  @override
  State<DsFlipCard> createState() => _DsFlipCardState();
}

class _DsFlipCardState extends State<DsFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.showBack) _controller.value = 1;
  }

  @override
  void didUpdateWidget(DsFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBack != oldWidget.showBack) {
      widget.showBack ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = _controller.value < 0.5;
    next ? _controller.forward() : _controller.reverse();
    widget.onFlip?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * pi;
          final isBackVisible = angle > pi / 2;
          final displayAngle = isBackVisible ? angle - pi : angle;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(displayAngle),
            child: isBackVisible ? widget.back : widget.front,
          );
        },
      ),
    );
  }
}
