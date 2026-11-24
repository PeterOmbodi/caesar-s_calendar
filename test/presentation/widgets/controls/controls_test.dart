import 'package:caesar_puzzle/presentation/theme/app_palette.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_bar_icon_button.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_button.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_menu_button.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_segmented_control.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_text_field.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(final TargetPlatform platform, final Widget child) => MaterialApp(
  theme: AppThemeData.of(AppPalette.classic, Brightness.light).copyWith(platform: platform),
  home: Scaffold(body: Center(child: child)),
);

Finder _widgetOf<T>() => find.byWidgetPredicate((final w) => w is T);

void main() {
  group('AppButton', () {
    testWidgets('builds the Material button for each variant', (final tester) async {
      await tester.pumpWidget(_app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {})));
      expect(_widgetOf<FilledButton>(), findsOneWidget);

      await tester.pumpWidget(
        _app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {}, variant: AppButtonVariant.outlined)),
      );
      expect(_widgetOf<OutlinedButton>(), findsOneWidget);

      await tester.pumpWidget(
        _app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {}, variant: AppButtonVariant.text)),
      );
      expect(_widgetOf<TextButton>(), findsOneWidget);

      await tester.pumpWidget(_app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {}, icon: Icons.add)));
      expect(_widgetOf<FilledButton>(), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('takes its height from the size on Material', (final tester) async {
      await tester.pumpWidget(
        _app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {}, size: AppButtonSize.large)),
      );
      final large = tester.widget<FilledButton>(_widgetOf<FilledButton>());
      expect(large.style!.minimumSize!.resolve({})!.height, 48);

      await tester.pumpWidget(_app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {})));
      final regular = tester.widget<FilledButton>(_widgetOf<FilledButton>());
      expect(regular.style!.minimumSize!.resolve({})!.height, 40);
    });

    testWidgets('builds a Cupertino button on iOS', (final tester) async {
      await tester.pumpWidget(
        _app(TargetPlatform.iOS, AppButton(label: 'Go', onPressed: () {}, size: AppButtonSize.large)),
      );
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(_widgetOf<FilledButton>(), findsNothing);
      expect(tester.widget<CupertinoButton>(find.byType(CupertinoButton)).minimumSize, const Size(50, 50));
    });

    testWidgets('outlined is a bordered button with the readable accent on iOS', (final tester) async {
      await tester.pumpWidget(
        _app(TargetPlatform.iOS, AppButton(label: 'Go', onPressed: () {}, variant: AppButtonVariant.outlined)),
      );
      final scheme = AppThemeData.of(AppPalette.classic, Brightness.light).colorScheme;
      expect(tester.renderObject<RenderParagraph>(find.text('Go')).text.style?.color, scheme.onSecondaryContainer);
    });

    testWidgets('a disabled filled button keeps a legible label on iOS', (final tester) async {
      await tester.pumpWidget(_app(TargetPlatform.iOS, const AppButton(label: 'Go', onPressed: null)));
      expect(
        tester.renderObject<RenderParagraph>(find.text('Go')).text.style?.color,
        GameColors.light.textSecondary,
      );
    });

    testWidgets('expands to the full width when asked', (final tester) async {
      await tester.pumpWidget(_app(TargetPlatform.android, AppButton(label: 'Go', onPressed: () {}, expand: true)));
      expect(tester.getSize(_widgetOf<FilledButton>()).width, tester.getSize(find.byType(Scaffold)).width);
    });
  });

  group('AppBarIconButton', () {
    testWidgets('is an IconButton with a tooltip on Material', (final tester) async {
      await tester.pumpWidget(
        _app(
          TargetPlatform.android,
          AppBarIconButton(
            icon: Icons.info_outline,
            cupertinoIcon: CupertinoIcons.info,
            label: 'Info',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.widget<IconButton>(find.byType(IconButton)).tooltip, 'Info');
    });

    testWidgets('is a Cupertino button with the Cupertino icon on iOS', (final tester) async {
      await tester.pumpWidget(
        _app(
          TargetPlatform.iOS,
          AppBarIconButton(
            icon: Icons.info_outline,
            cupertinoIcon: CupertinoIcons.info,
            label: 'Info',
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.info), findsOneWidget);
    });
  });

  group('AppTextField', () {
    testWidgets('is an outlined TextField with a label on Material', (final tester) async {
      await tester.pumpWidget(_app(TargetPlatform.android, const AppTextField(label: 'Code', errorText: 'Wrong')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.labelText, 'Code');
      expect(field.decoration!.errorText, 'Wrong');
    });

    testWidgets('is a CupertinoTextField with the label above on iOS', (final tester) async {
      await tester.pumpWidget(_app(TargetPlatform.iOS, const AppTextField(label: 'Code', errorText: 'Wrong')));
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Wrong'), findsOneWidget);
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('is the app selector on Material and reports the picked segment', (final tester) async {
      int? picked;
      await tester.pumpWidget(
        _app(
          TargetPlatform.android,
          AppSegmentedControl<int>(segments: const {1: 'A', 2: 'B'}, value: 1, onChanged: (final v) => picked = v),
        ),
      );
      expect(find.byType(SegmentedButton<int>), findsNothing);
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('B'));
      expect(picked, 2);
    });

    testWidgets('Material segments meet the Android touch target size', (final tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          TargetPlatform.android,
          AppSegmentedControl<int>(segments: const {1: 'A', 2: 'B'}, value: 1, onChanged: (_) {}),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('AppMenuButton', () {
    List<AppMenuItem> items(final List<String> log) => [
      AppMenuItem(
        label: 'Rename',
        icon: Icons.edit,
        cupertinoIcon: CupertinoIcons.pencil,
        onSelected: () => log.add('r'),
      ),
      AppMenuItem(
        label: 'Delete',
        icon: Icons.delete,
        cupertinoIcon: CupertinoIcons.delete,
        onSelected: () => log.add('d'),
        destructive: true,
      ),
    ];

    testWidgets('is a popup menu on Material', (final tester) async {
      final log = <String>[];
      await tester.pumpWidget(_app(TargetPlatform.android, AppMenuButton(items: items(log))));
      expect(find.byType(PopupMenuButton<AppMenuItem>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<AppMenuItem>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(log, ['d']);
    });

    testWidgets('opens a glass menu on iOS and runs the picked item', (final tester) async {
      final log = <String>[];
      await tester.pumpWidget(_app(TargetPlatform.iOS, AppMenuButton(items: items(log))));
      expect(find.byType(PopupMenuButton<AppMenuItem>), findsNothing);

      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(log, ['r']);
      expect(find.text('Rename'), findsNothing);
    });
  });
}
