import 'dart:async';
import 'dart:io';

import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/profile_localizations.dart';
import '../bloc/profile_cubit.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pickAvatar(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    unawaited(context.read<ProfileCubit>().updateAvatar(File(picked.path)));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = ProfileLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await GetIt.I<LogoutUseCase>()();
    GetIt.I<BiometricSessionGate>().unlocked = false;
    if (context.mounted) {
      unawaited(context.router.replacePath(AppRoutes.login));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileLocalizations.of(context)!;
    final isGuest = GetIt.I<AuthRepository>().isCurrentUserAnonymous;

    return BlocProvider(
      create: (_) => GetIt.I<ProfileCubit>()..loadProfile(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) => switch (state) {
            ProfileInitial() || ProfileLoading() => const DsLoading(),
            ProfileLoaded(:final profile) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: isGuest
                  ? [
                      DsCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              Text(
                                l10n.guestBannerMessage,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DsButton(
                                label: l10n.guestCreateAccount,
                                onPressed: () => context.router.pushPath(
                                  AppRoutes.register,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  : [
                      Center(
                        child: Stack(
                          children: [
                            _Avatar(avatarUrl: profile.avatarUrl),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () => _pickAvatar(context),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (profile.bio != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(profile.bio!, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      DsButton(
                        label: l10n.editProfile,
                        variant: DsButtonVariant.outlined,
                        onPressed: () =>
                            context.router.pushPath(AppRoutes.editProfile),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DsButton(
                        label: l10n.logout,
                        variant: DsButtonVariant.text,
                        onPressed: () => _confirmLogout(context),
                      ),
                    ],
            ),
            ProfileFailure(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(message),
                  const SizedBox(height: AppSpacing.md),
                  DsButton(
                    label: l10n.retry,
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                  ),
                ],
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        child: Icon(Icons.person, size: 50),
      );
    }
    final isRemote = avatarUrl!.startsWith('http');
    return CircleAvatar(
      radius: 50,
      backgroundImage: isRemote
          ? NetworkImage(avatarUrl!)
          : FileImage(File(avatarUrl!)) as ImageProvider,
    );
  }
}
