import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Expected = ({
  WindowClass window,
  BoardArrangement arrangement,
  ToolbarPlacement toolbar,
  double maxCell,
  bool settingsDocked,
});

void main() {
  group('WindowClass.fromSize', () {
    test('width thresholds', () {
      expect(WindowClass.fromSize(const Size(599, 900)), WindowClass.compact);
      expect(WindowClass.fromSize(const Size(600, 900)), WindowClass.medium);
      expect(WindowClass.fromSize(const Size(1023, 700)), WindowClass.medium);
      expect(WindowClass.fromSize(const Size(1024, 700)), WindowClass.expanded);
    });

    test('compact height keeps the window compact', () {
      expect(WindowClass.fromSize(const Size(1000, 479)), WindowClass.compact);
      expect(WindowClass.fromSize(const Size(1100, 479)), WindowClass.compact);
      expect(WindowClass.fromSize(const Size(1100, 480)), WindowClass.expanded);
    });

    test('wide portrait window is medium, not expanded', () {
      expect(WindowClass.fromSize(const Size(1024, 1366)), WindowClass.medium);
    });
  });

  group('ScreenSpec matrix', () {
    const compactPortrait = (
      window: WindowClass.compact,
      arrangement: BoardArrangement.stacked,
      toolbar: ToolbarPlacement.bottomBar,
      maxCell: ScreenSpec.compactMaxCell,
      settingsDocked: false,
    );
    const compactLandscape = (
      window: WindowClass.compact,
      arrangement: BoardArrangement.sideBySide,
      toolbar: ToolbarPlacement.compactRail,
      maxCell: ScreenSpec.compactMaxCell,
      settingsDocked: false,
    );
    const mediumPortrait = (
      window: WindowClass.medium,
      arrangement: BoardArrangement.stacked,
      toolbar: ToolbarPlacement.bottomBar,
      maxCell: ScreenSpec.mediumMaxCell,
      settingsDocked: false,
    );
    const expandedDocked = (
      window: WindowClass.expanded,
      arrangement: BoardArrangement.sideBySide,
      toolbar: ToolbarPlacement.labeledRail,
      maxCell: ScreenSpec.expandedMaxCell,
      settingsDocked: true,
    );

    final cases = <String, (Size, _Expected)>{
      'iPhone SE portrait': (const Size(375, 667), compactPortrait),
      'iPhone SE landscape': (const Size(667, 375), compactLandscape),
      'iPhone 16 Pro Max portrait': (const Size(440, 956), compactPortrait),
      'iPhone 16 Pro Max landscape': (const Size(956, 440), compactLandscape),
      'iPad mini portrait': (const Size(744, 1133), mediumPortrait),
      'iPad Pro 13 portrait': (const Size(1032, 1376), mediumPortrait),
      'iPad Pro 13 landscape': (const Size(1376, 1032), expandedDocked),
      'iPad Pro 13 half Split View': (const Size(678, 1032), mediumPortrait),
      'iPad Pro 13 one-third Split View': (const Size(320, 1032), compactPortrait),
      'foldable unfolded': (const Size(673, 841), mediumPortrait),
      'desktop window': (const Size(1440, 900), expandedDocked),
      'expanded below docked settings': (
        const Size(1100, 800),
        (
          window: WindowClass.expanded,
          arrangement: BoardArrangement.sideBySide,
          toolbar: ToolbarPlacement.labeledRail,
          maxCell: ScreenSpec.expandedMaxCell,
          settingsDocked: false,
        ),
      ),
    };

    for (final MapEntry(key: name, value: (size, expected)) in cases.entries) {
      test(name, () {
        final spec = ScreenSpec(size: size, family: ChromeFamily.glass);
        expect(spec.window, expected.window, reason: 'window');
        expect(spec.arrangement, expected.arrangement, reason: 'arrangement');
        expect(spec.toolbar, expected.toolbar, reason: 'toolbar');
        expect(spec.maxCell, expected.maxCell, reason: 'maxCell');
        expect(
          spec.trayScale,
          expected.window == WindowClass.compact ? ScreenSpec.compactTrayScale : ScreenSpec.tabletTrayScale,
          reason: 'trayScale',
        );
        expect(spec.settingsDocked, expected.settingsDocked, reason: 'settingsDocked');
      });
    }

    test('settings dock exactly at the old 1124 breakpoint', () {
      expect(const ScreenSpec(size: Size(1123, 800), family: ChromeFamily.glass).settingsDocked, isFalse);
      expect(const ScreenSpec(size: Size(1124, 800), family: ChromeFamily.glass).settingsDocked, isTrue);
    });
  });

  group('ChromeFamily.forPlatform', () {
    test('maps platforms to families', () {
      expect(ChromeFamily.forPlatform(TargetPlatform.iOS, isWeb: false), ChromeFamily.glass);
      expect(ChromeFamily.forPlatform(TargetPlatform.macOS, isWeb: false), ChromeFamily.glass);
      expect(ChromeFamily.forPlatform(TargetPlatform.android, isWeb: false), ChromeFamily.material);
      expect(ChromeFamily.forPlatform(TargetPlatform.windows, isWeb: false), ChromeFamily.material);
      expect(ChromeFamily.forPlatform(TargetPlatform.iOS, isWeb: true), ChromeFamily.glass);
      expect(ChromeFamily.forPlatform(TargetPlatform.android, isWeb: true), ChromeFamily.material);
      expect(ChromeFamily.forPlatform(TargetPlatform.linux, isWeb: true), ChromeFamily.web);
    });
  });

  group('ScreenSpec.of', () {
    tearDown(() => ChromeFamily.debugOverride = null);

    Future<ScreenSpec> pumpSpec(final WidgetTester tester, {required final TargetPlatform platform}) async {
      late ScreenSpec spec;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(744, 1133)),
          child: Theme(
            data: ThemeData(platform: platform),
            child: Builder(
              builder: (final context) {
                spec = ScreenSpec.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return spec;
    }

    testWidgets('reads window size and platform', (final tester) async {
      final spec = await pumpSpec(tester, platform: TargetPlatform.android);
      expect(spec.size, const Size(744, 1133));
      expect(spec.window, WindowClass.medium);
      expect(spec.family, ChromeFamily.material);
    });

    testWidgets('debug override wins over the platform', (final tester) async {
      ChromeFamily.debugOverride = ChromeFamily.web;
      final spec = await pumpSpec(tester, platform: TargetPlatform.iOS);
      expect(spec.family, ChromeFamily.web);
    });
  });
}
