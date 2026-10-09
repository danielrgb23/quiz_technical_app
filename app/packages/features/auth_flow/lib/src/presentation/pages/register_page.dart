import 'dart:async';

import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../l10n/generated/auth_localizations.dart';
import '../auth_success_handler.dart';
import '../bloc/register_cubit.dart';

@RoutePage()
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context)!;
    final isGuestUpgrade = GetIt.I<AuthRepository>().isCurrentUserAnonymous;

    return BlocProvider(
      create: (_) => GetIt.I<RegisterCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isGuestUpgrade ? l10n.upgradeAccountTitle : l10n.registerTitle,
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocConsumer<RegisterCubit, RegisterState>(
            listener: (context, state) {
              switch (state) {
                case RegisterSuccess(:final user):
                  unawaited(handleAuthSuccess(context, user));
                case RegisterAccountExists(:final email):
                  // A conta já existe — a mesclagem de progresso roda no
                  // login com essas mesmas credenciais (ver LinkAnonymous
                  // orchestration no app-level, M4). replacePath em vez de
                  // pushPath pra não empilhar Login duas vezes quando o
                  // Cadastrar já veio da tela de Login.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.accountExistsMessage(email))),
                  );
                  context.router.replacePath(AppRoutes.login);
                case RegisterFailure(:final message):
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                case RegisterInitial() || RegisterLoading():
                  break;
              }
            },
            builder: (context, state) {
              final isLoading = state is RegisterLoading;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _RegisterForm(
                  isLoading: isLoading,
                  isGuestUpgrade: isGuestUpgrade,
                  hint: isGuestUpgrade ? l10n.upgradeAccountHint : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({
    required this.isLoading,
    required this.isGuestUpgrade,
    this.hint,
  });

  final bool isLoading;
  final bool isGuestUpgrade;
  final String? hint;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.hint != null) ...[
            Text(widget.hint!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          DsTextField(
            controller: _nameController,
            label: l10n.name,
            hint: l10n.nameHint,
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.nameRequired;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DsTextField(
            controller: _emailController,
            label: l10n.email,
            hint: l10n.emailHint,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.emailRequired;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DsTextField(
            controller: _passwordController,
            label: l10n.password,
            hint: l10n.passwordHint,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.passwordRequired;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DsButton(
            label: l10n.register,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _onSubmit,
          ),
          const SizedBox(height: AppSpacing.md),
          DsButton(
            label: l10n.login,
            variant: DsButtonVariant.text,
            onPressed: () => context.router.pushPath(AppRoutes.login),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterCubit>().register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        isGuestUpgrade: widget.isGuestUpgrade,
      );
    }
  }
}
