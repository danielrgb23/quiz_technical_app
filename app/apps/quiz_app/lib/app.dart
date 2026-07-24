import 'package:auth_flow/auth_flow.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_flow/home_flow.dart';
import 'package:onboarding/onboarding.dart';
import 'package:profile_flow/profile_flow.dart';

import 'app_router.dart';
import 'l10n/generated/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.config(
        deepLinkTransformer: _resolveQuizAppScheme,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DsLocalizations.delegate,
        AuthLocalizations.delegate,
        HomeLocalizations.delegate,
        OnboardingLocalizations.delegate,
        ProfileLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Idioma do dispositivo quando suportado; fallback para pt (Spec 02).
      localeResolutionCallback: (locale, supported) {
        if (locale != null) {
          for (final s in supported) {
            if (s.languageCode == locale.languageCode) return s;
          }
        }
        return const Locale('pt');
      },
    );
  }
}

/// Para o custom scheme `quizapp://host/path`, o `host` é interpretado
/// como authority (não como segmento de path) pelo parser padrão do
/// auto_route, então `quizapp://quiz/flutter` chegaria só como `/flutter`.
/// Reconstrói o path prefixando o host quando o scheme é `quizapp`.
Future<Uri> _resolveQuizAppScheme(Uri uri) async {
  if (uri.scheme != 'quizapp' || uri.host.isEmpty) return uri;
  return uri.replace(host: '', path: '/${uri.host}${uri.path}');
}
