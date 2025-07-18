import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';
import 'injection.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  configureInjection();
  final themeNotifier = ThemeModeNotifier();
  await themeNotifier.load();
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: Builder(builder: (context) {
        FlutterNativeSplash.remove();
        return const MyApp();
      }),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeModeNotifier>();
    return MaterialApp(
      onGenerateTitle: (context) => S.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.mode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        AppColors.update(brightness);
        return child!;
      },
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: Material(
        child: const PuzzleScreen(),
      ),
    );
  }
}
