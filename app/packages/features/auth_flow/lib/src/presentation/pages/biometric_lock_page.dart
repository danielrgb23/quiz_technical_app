import 'dart:async';

import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../l10n/generated/auth_localizations.dart';

/// Shown on launch when biometric unlock is enabled and this app session
/// hasn't been unlocked yet (see [BiometricSessionGate] /
/// `BiometricGuard` in quiz_app). Convenience gate only — Firebase Auth's
/// own session and SecureStorage are what actually protect the data;
/// this just stops someone with the unlocked phone in hand from opening
/// the app straight to it.
@RoutePage()
class BiometricLockPage extends StatefulWidget {
  const BiometricLockPage({super.key});

  @override
  State<BiometricLockPage> createState() => _BiometricLockPageState();
}

class _BiometricLockPageState extends State<BiometricLockPage> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    final l10n = AuthLocalizations.of(context)!;
    final success = await GetIt.I<BiometricAuthService>().authenticate(
      reason: l10n.biometricLockMessage,
    );

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (success) {
      GetIt.I<BiometricSessionGate>().unlocked = true;
      if (mounted) unawaited(context.router.replacePath(AppRoutes.home));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await GetIt.I<LogoutUseCase>()();
    GetIt.I<BiometricSessionGate>().unlocked = false;
    if (context.mounted) {
      unawaited(context.router.replacePath(AppRoutes.login));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 72),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.biometricLockTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.biometricLockMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              DsButton(
                label: l10n.biometricLockRetry,
                isLoading: _authenticating,
                onPressed: _authenticating ? null : _authenticate,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: l10n.biometricLockUseLogout,
                variant: DsButtonVariant.text,
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
