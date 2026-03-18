import 'package:caesar_puzzle/presentation/bloc/app_bloc_observer.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
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

import 'generated/l10n.dart';
import 'infrastructure/firebase/firebase_bootstrap.dart';
import 'infrastructure/sync/sync_runner.dart';
import 'injection.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await FirebaseBootstrap.ensureInitialized();
  configureInjection();
  getIt<SyncRunner>().start();
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
  Widget build(final BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => SettingsCubit()),
      BlocProvider(create: (_) => getIt<AuthCubit>()),
    ],
    child: BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (final p, final n) => p.theme != n.theme || p.localeCode != n.localeCode,
      builder: (final context, final settings) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (final context) => S.of(context).appTitle,
        theme: AppThemeData.light,
        darkTheme: AppThemeData.dark,
        themeMode: settings.theme.toThemeMode(),
        locale: settings.locale,
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
