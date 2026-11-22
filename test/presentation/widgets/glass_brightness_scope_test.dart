import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('glass follows the app theme when it differs from the system theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    Brightness? glassBrightness;

    await tester.pumpWidget(
      GlassBrightnessScope(
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              glassBrightness = GlassTheme.brightnessOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(glassBrightness, Brightness.dark);
  });
}
