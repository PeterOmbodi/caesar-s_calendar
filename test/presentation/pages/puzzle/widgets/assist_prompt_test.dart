import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/assist_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<bool>> ask(
    final WidgetTester tester,
    final AssistGate gate, {
    final bool countsForRecords = true,
  }) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (final c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final allowed = confirmAssist(context, gate: gate, countsForRecords: () async => countsForRecords);
    await tester.pumpAndSettle();
    return allowed;
  }

  Future<void> tapText(final WidgetTester tester, final String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('an open gate runs without a dialog', (final tester) async {
    final allowed = await ask(tester, AssistGate.open);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await allowed, isTrue);
  });

  testWidgets('no solutions shows a notice and does not run', (final tester) async {
    final allowed = await ask(tester, AssistGate.noSolutions);
    expect(find.text(S.current.solutionsNotFoundDialogMessage), findsOneWidget);
    await tapText(tester, S.current.ok);
    expect(await allowed, isFalse);
  });

  testWidgets('a game that counts for records warns, and continue runs the assist', (final tester) async {
    final allowed = await ask(tester, AssistGate.warnRecords);
    expect(find.text(S.current.assistNoRecordsMessage), findsOneWidget);
    await tapText(tester, S.current.assistNoRecordsContinue);
    expect(await allowed, isTrue);
  });

  testWidgets('cancel keeps the game in records', (final tester) async {
    final allowed = await ask(tester, AssistGate.warnRecords);
    await tapText(tester, S.current.solutionsFoundDialogCancel);
    expect(await allowed, isFalse);
  });

  testWidgets('a game that already does not count runs without a warning', (final tester) async {
    final allowed = await ask(tester, AssistGate.warnRecords, countsForRecords: false);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await allowed, isTrue);
  });
}
