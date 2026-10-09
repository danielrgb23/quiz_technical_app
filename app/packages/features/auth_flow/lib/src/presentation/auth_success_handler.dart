import 'dart:async';

import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';

/// Common post-login steps for both [LoginPage] and [RegisterPage]:
/// register for push, then go to Home.
Future<void> handleAuthSuccess(BuildContext context, User user) async {
  unawaited(GetIt.I<NotificationService>().initialize(uid: user.id));

  // replacePath, não pushPath: sem isso a tela de auth fica empilhada
  // sob a Home e aparece uma seta de voltar que não deveria existir
  // depois de autenticado.
  if (context.mounted) {
    unawaited(context.router.replacePath(AppRoutes.home));
  }
}
