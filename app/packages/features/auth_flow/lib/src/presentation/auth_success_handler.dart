import 'dart:async';

import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';

import '../l10n/generated/auth_localizations.dart';

/// Common post-login steps for both [LoginPage] and [RegisterPage]:
/// register for push, offer biometric unlock once, then go to Home.
Future<void> handleAuthSuccess(BuildContext context, User user) async {
  unawaited(GetIt.I<NotificationService>().initialize(uid: user.id));

  await _maybePromptBiometric(context);

  // replacePath, não pushPath: sem isso a tela de auth fica empilhada
  // sob a Home e aparece uma seta de voltar que não deveria existir
  // depois de autenticado.
  if (context.mounted) {
    unawaited(context.router.replacePath(AppRoutes.home));
  }
}

Future<void> _maybePromptBiometric(BuildContext context) async {
  final prefs = GetIt.I<BiometricPreferences>();
  if (await prefs.wasPrompted) return;
  await prefs.markPrompted();

  final available = await GetIt.I<BiometricAuthService>().isAvailable;
  if (!available || !context.mounted) return;

  final l10n = AuthLocalizations.of(context)!;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.biometricEnableTitle),
      content: Text(l10n.biometricEnableMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.biometricEnableDismiss),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.biometricEnableConfirm),
        ),
      ],
    ),
  );

  if (accepted == true) {
    await prefs.setEnabled(true);
    // Already proved identity via this very login — no need to
    // immediately re-challenge with Face ID before reaching Home.
    GetIt.I<BiometricSessionGate>().unlocked = true;
  }
}
