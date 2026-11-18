import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_standings.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(10000000);

  Future<void> pumpStandings(final WidgetTester tester, {required final double width}) async {
    // The countdown's timer must stop before the test ends, also when an expectation fails.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 400,
              child: RaceStandings(
                players: const [
                  RacePlayer(uid: 'a', nickname: 'Fleet Moose 77', colorIndex: 0, joinedAt: 0, durationMs: 599900),
                  RacePlayer(uid: 'b', nickname: 'Nimble Robin 83', colorIndex: 1, joinedAt: 1, placed: 5),
                ],
                myUid: 'b',
                isStarted: true,
                totalPieces: 8,
                graceEndsAtMs: now.millisecondsSinceEpoch + 15000,
                now: () => now,
                solverLevel: null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final width in [128.0, 226.0]) {
    testWidgets('a finish time and the time to finish fit a column $width wide', (final tester) async {
      await pumpStandings(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(find.text('9:59.9'), findsOneWidget);
    });
  }

  testWidgets('a narrow column shows short names', (final tester) async {
    await pumpStandings(tester, width: 128);
    expect(find.text('FM77'), findsOneWidget);
    expect(find.text('NR83'), findsOneWidget);
  });
}
