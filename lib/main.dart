import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'generated/l10n.dart';
import 'injection.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  configureInjection();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );
  Bloc.observer = AppBlocObserver();
  runApp(
    Builder(
      builder: (final context) {
        FlutterNativeSplash.remove();
        return const MyApp();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => BlocProvider(
    create: (final context) => SettingsCubit(),
    child: BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (final p, final n) => p.theme != n.theme,
      builder: (final context, final settings) => MaterialApp(
        onGenerateTitle: (final context) => S.of(context).appTitle,
        theme: AppThemeData.light,
        darkTheme: AppThemeData.dark,
        themeMode: settings.theme.toThemeMode(),
        builder: (final context, final child) {
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
        localeResolutionCallback: (final locale, final supportedLocales) {
          if (locale == null) return supportedLocales.first;
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Material(child: const PuzzleScreen()),
      ),
    ),
  );
}
