import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_app_bar.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => ChromeFamily.debugOverride = null);

  for (final family in [ChromeFamily.glass, ChromeFamily.material]) {
    testWidgets('history app bar exposes picker action for $family', (final tester) async {
      ChromeFamily.debugOverride = family;
      var pickerPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.light.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(appBar: HistoryAppBar(onPickDate: () => pickerPressed = true)),
        ),
      );

      expect(find.text(S.current.historyTitle), findsOneWidget);
      await tester.tap(
        find.byIcon(family == ChromeFamily.glass ? CupertinoIcons.calendar : Icons.calendar_month_outlined),
      );
      expect(pickerPressed, isTrue);
    });
  }
}
