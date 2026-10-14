import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/date_selector.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_app_bar.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_content_layout.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_overview.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/puzzle_day_picker.dart';
import 'package:caesar_puzzle/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements PuzzleHistoryRepository {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cubit extends HistoryCubit {
  _Cubit() : super(historyUseCase: PuzzleHistoryUseCase(_Repository())) {
    emit(
      state.copyWith(
        isSessionsLoading: false,
        isCalendarLoading: false,
        isPeriodStatsLoading: false,
        sessions: [
          PuzzleSessionData(
            id: 'session',
            puzzleDate: DateTime(2024, 2, 29),
            configId: 'custom',
            difficulty: PuzzleSessionDifficulty.hard,
            status: PuzzleSessionStatus.unsolved,
            startedAt: DateTime(2026, 10, 13, 11, 49).millisecondsSinceEpoch,
            firstMoveAt: null,
            lastResumedAt: null,
            activeElapsedMs: 31000,
            updatedAt: DateTime(2026, 10, 13, 11, 50).millisecondsSinceEpoch,
            completedAt: null,
            moveIndex: 6,
            moveHistoryVersion: 1,
            pieces: [],
            moveHistory: [],
          ),
        ],
      ),
    );
  }

  @override
  void setStatsPeriod(final StatsPeriod period) => emit(state.copyWith(statsPeriod: period));
  @override
  void setStatsYearScope(final StatsYearScope scope) => emit(state.copyWith(statsYearScope: scope));
}

class _HistoryTestHarness extends StatefulWidget {
  const _HistoryTestHarness({required this.cubit});

  final HistoryCubit cubit;

  @override
  State<_HistoryTestHarness> createState() => _HistoryTestHarnessState();
}

class _HistoryTestHarnessState extends State<_HistoryTestHarness> {
  int _tab = 0;

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) => Material(
      type: MaterialType.transparency,
      child: HistoryContentLayout(
        state: state,
        activeTab: _tab,
        onTabChanged: (final tab) => setState(() => _tab = tab),
        centerSelectionRequest: 0,
        onStartPuzzle: (_) {},
        onResumeSession: (_) {},
      ),
    ),
  );
}

Widget app(final Widget child, {final bool dark = false}) => MaterialApp(
  theme: (dark ? AppThemeData.dark : AppThemeData.light).copyWith(platform: TargetPlatform.iOS),
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  locale: const Locale('en'),
  home: child,
);

void main() {
  for (final dark in [false, true]) {
    testWidgets('history header renders the app background in ${dark ? 'dark' : 'light'} mode', (final tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        app(
          RepaintBoundary(
            key: key,
            child: Scaffold(appBar: HistoryAppBar(onPickDate: () {})),
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pixel = await tester.runAsync(() async {
        final image = await boundary.toImage();
          final bytes = (await image.toByteData())!;
        final offset = (10 * image.width + 100) * 4;
        final result = [for (var i = 0; i < 4; i++) bytes.getUint8(offset + i)];
        image.dispose();
        return result;
      });
      expect(pixel, dark ? [18, 16, 23, 255] : [245, 242, 236, 255]);
    });
  }

  testWidgets('heatmap exposes one summary instead of day controls', (final tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: HistoryOverview(
            selectedDate: DateTime(2024, 7, 15),
            rangeStart: DateTime(2024),
            rangeEnd: DateTime(2024, 12, 31),
            stats: const [],
            onDateTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('^${S.current.historyTitle}:')), findsOneWidget);
    expect(find.bySemanticsLabel('January 1'), findsNothing);
    semantics.dispose();
  });

  testWidgets('heatmap centers selection and clamps at both ends', (final tester) async {
    for (final date in [DateTime(2024), DateTime(2024, 7, 15), DateTime(2024, 12, 31)]) {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SizedBox(
              width: 360,
              child: DateSelector(
                key: ValueKey(date),
                selectedDate: date,
                rangeStart: DateTime(2024),
                rangeEnd: DateTime(2024, 12, 31),
                stats: const [],
                onDateTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester.widget<SingleChildScrollView>(
        find.descendant(of: find.byType(DateSelector), matching: find.byType(SingleChildScrollView)),
      );
      final position = scroll.controller!.position;
      final dayIndex = DateTime.utc(2024, date.month, date.day).difference(DateTime.utc(2024)).inDays;
      final expected = (12 + (dayIndex ~/ 7) * 28 + 12 - position.viewportDimension / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      expect(position.pixels, closeTo(expected, .01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('changing selection preserves manual heatmap scroll', (final tester) async {
    Widget build(final DateTime date, {final int centerRequest = 0}) => app(
      Scaffold(
        body: SizedBox(
          width: 360,
          child: DateSelector(
            selectedDate: date,
            centerSelectionRequest: centerRequest,
            rangeStart: DateTime(2024),
            rangeEnd: DateTime(2024, 12, 31),
            stats: const [],
            onDateTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(build(DateTime(2024, 7, 15)));
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(
      find.descendant(of: find.byType(DateSelector), matching: find.byType(SingleChildScrollView)),
    );
    scroll.controller!.jumpTo(100);
    await tester.pumpWidget(build(DateTime(2024, 8, 20)));
    await tester.pumpAndSettle();
    expect(scroll.controller!.offset, 100);
    await tester.pumpWidget(build(DateTime(2024, 8, 20), centerRequest: 1));
    await tester.pumpAndSettle();
    final position = scroll.controller!.position;
    final dayIndex = DateTime.utc(2024, 8, 20).difference(DateTime.utc(2024)).inDays;
    final expected = (12 + (dayIndex ~/ 7) * 28 + 12 - position.viewportDimension / 2).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    expect(position.pixels, closeTo(expected, .01));
  });

  testWidgets('calendar returns February 29 with hidden leap-year anchor', (final tester) async {
    DateTime? result;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (final context) => TextButton(
              onPressed: () async => result = await showPuzzleDayPicker(context, selectedDate: DateTime(2026, 3, 20)),
              child: const Text('Pick'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('previous-month')));
    await tester.pumpAndSettle();
    expect(find.text('February'), findsOneWidget);
    expect(find.textContaining('2024'), findsNothing);
    expect(find.textContaining('2026'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('day-29')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2024, 2, 29));
  });

  testWidgets('month navigation clamps days and cancel leaves selection untouched', (final tester) async {
    DateTime? result = DateTime(2024, 1, 31);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (final context) => TextButton(
              onPressed: () async => result = await showPuzzleDayPicker(context, selectedDate: result!),
              child: const Text('Pick'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-month')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('day-29')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-30')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  for (final size in [const Size(768, 1024), const Size(1024, 768)]) {
    testWidgets('tablet keeps overview above session and statistics columns at $size', (final tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = _Cubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        app(
          BlocProvider<HistoryCubit>.value(
            value: cubit,
            child: _HistoryTestHarness(cubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overview = tester.getRect(find.byKey(const ValueKey('history-tablet-overview')));
      final content = tester.getRect(find.byKey(const ValueKey('history-tablet-content')));
      expect(content.top, greaterThanOrEqualTo(overview.bottom));
      expect(content.width, closeTo(size.width, 1));
    });
  }

  for (final size in [const Size(390, 844), const Size(844, 390), const Size(667, 375)]) {
    for (final dark in [false, true]) {
      testWidgets('history and stats fit $size dark=$dark', (final tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final cubit = _Cubit();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          app(
            BlocProvider<HistoryCubit>.value(
              value: cubit,
              child: _HistoryTestHarness(cubit: cubit),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(HistoryContentLayout), findsOneWidget);
        if (size.width < 720) {
          await tester.tap(find.text(S.current.historyTabStatistics));
          await tester.pumpAndSettle();
        }
        expect(find.text(S.current.historyYearScopeCurrent), findsOneWidget);
        expect(find.text(S.current.historyYearScopeAll), findsOneWidget);
        await tester.tap(find.text(S.current.historyPeriodMonth));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
