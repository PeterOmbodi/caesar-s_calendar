import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/bloc/leaderboard_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/leaderboard/widgets/leaderboard_row_view.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRow(final WidgetTester tester, final LeaderboardRow row) => tester.pumpWidget(
    MaterialApp(
      theme: AppThemeData.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: LeaderboardRowView(row: row)),
    ),
  );

  testWidgets('a time row is announced as one label without the avatar letter', (final tester) async {
    final handle = tester.ensureSemantics();
    await pumpRow(
      tester,
      const LeaderboardRow(
        rank: 3,
        nickname: 'Swift Otter 47',
        colorIndex: 0,
        value: TimeValue(timeMs: 83000, extraSolutions: 2),
        isMe: true,
      ),
    );

    expect(
      find.bySemanticsLabel('Place 3, Swift Otter 47, You, time 01:23, more solutions: 2'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('S'), findsNothing);
    handle.dispose();
  });

  testWidgets('points and streak rows name their values', (final tester) async {
    final handle = tester.ensureSemantics();
    await pumpRow(
      tester,
      const LeaderboardRow(
        rank: 1,
        nickname: 'Peter O.',
        colorIndex: 1,
        value: PointsValue(points: 120, days: 6),
        isMe: false,
      ),
    );
    expect(find.bySemanticsLabel('Place 1, Peter O., points: 120, days: 6'), findsOneWidget);

    await pumpRow(
      tester,
      const LeaderboardRow(
        rank: 2,
        nickname: 'Peter O.',
        colorIndex: 1,
        value: StreakValue(best: 12, current: 0),
        isMe: false,
      ),
    );
    expect(find.bySemanticsLabel('Place 2, Peter O., best streak: 12, current: 0'), findsOneWidget);
    handle.dispose();
  });
}
