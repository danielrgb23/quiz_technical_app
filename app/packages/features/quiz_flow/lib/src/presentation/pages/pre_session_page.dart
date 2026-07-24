import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:quiz_module/quiz_module.dart';

import '../../l10n/generated/quiz_localizations.dart';
import '../../routes/quiz_flow_routes.dart';

/// Pré-sessão (deeplink `/quiz/{topic}`): tópico, quantidade, iniciar.
@RoutePage()
class PreSessionPage extends StatefulWidget {
  const PreSessionPage({@PathParam('topic') required this.topic, super.key});

  final String topic;

  @override
  State<PreSessionPage> createState() => _PreSessionPageState();
}

class _PreSessionPageState extends State<PreSessionPage> {
  int _size = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = QuizLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preSessionTitle(widget.topic))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.questionCountLabel),
            const SizedBox(height: AppSpacing.sm),
            Slider(
              value: _size.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              label: '$_size',
              onChanged: (value) => setState(() => _size = value.round()),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: DsButton(
                label: l10n.startButtonLabel,
                onPressed: () => context.router.push(
                  QuizSessionRoute(
                    mode: SessionMode.topic,
                    topic: widget.topic,
                    size: _size,
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
