import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/bloc/app_bloc_observer.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/palette_scope.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:caesar_puzzle/presentation/widgets/system_bars.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
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
  getIt<SyncRunner>().start(requestImmediateSync: false);
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
    await LiquidGlassWidgets.initialize();
  }
  Bloc.observer = AppBlocObserver();
  if (kIsWeb) {
    // Right click flips a piece instead of opening the browser menu.
    await BrowserContextMenu.disableContextMenu();
  }
  final systemPalette = await _loadSystemPalette();
  runApp(
    GlassBrightnessScope(
      child: Builder(
        builder: (final context) {
          FlutterNativeSplash.remove();
          return MyApp(systemPalette: systemPalette);
        },
      ),
    ),
  );
}

/// Material You colours from the wallpaper; Android 12+ only, read once at launch.
Future<AppPalette?> _loadSystemPalette() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (corePalette == null) return null;
    return AppPalette.fromSeed(id: AppPaletteId.system, seed: Color(corePalette.primary.get(40)));
  } on PlatformException {
    return null;
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required final AppPalette? systemPalette}) : _palettes = [...AppPalette.presets, ?systemPalette];

  final List<AppPalette> _palettes;

  @override
  Widget build(final BuildContext context) => PaletteScope(
    available: _palettes,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<PublicProfileCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (final p, final n) => p.theme != n.theme || p.palette != n.palette || p.localeCode != n.localeCode,
        builder: (final context, final settings) {
          final palette = AppPalette.resolve(settings.palette, _palettes);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (final context) => S.of(context).appTitle,
            theme: AppThemeData.of(palette, Brightness.light),
            darkTheme: AppThemeData.of(palette, Brightness.dark),
            themeMode: settings.theme.toThemeMode(),
            locale: settings.locale,
            builder: (final context, final child) {
              final theme = Theme.of(context);
              AppColors.update(GameColors.of(context), theme.brightness);
              final app = SystemBars(child: child!);
              if (ScreenSpec.of(context).family != ChromeFamily.glass) return app;
              return Theme(
                data: theme.copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: GameColors.of(context).icon.withValues(alpha: 0.12),
                ),
                child: app,
              );
            },
            localizationsDelegates: [S.delegate, ...GlobalMaterialLocalizations.delegates],
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
          );
        },
      ),
    ),
  );
}
