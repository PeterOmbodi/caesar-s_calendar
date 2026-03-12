import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';

class HistoryState {
  const HistoryState({
    required this.selectedDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.calendarStats,
    required this.sessions,
    required this.isCalendarLoading,
    required this.isSessionsLoading,
    required this.errorMessage,
  });

  factory HistoryState.initial(final DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return HistoryState(
      selectedDate: day,
      rangeStart: DateTime(day.year),
      rangeEnd: DateTime(day.year, 12, 31),
      calendarStats: const [],
      sessions: const [],
      isCalendarLoading: true,
      isSessionsLoading: true,
      errorMessage: null,
    );
  }

  final DateTime selectedDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarDayStats> calendarStats;
  final List<PuzzleSessionData> sessions;
  final bool isCalendarLoading;
  final bool isSessionsLoading;
  final String? errorMessage;

  HistoryState copyWith({
    final DateTime? selectedDate,
    final DateTime? rangeStart,
    final DateTime? rangeEnd,
    final List<CalendarDayStats>? calendarStats,
    final List<PuzzleSessionData>? sessions,
    final bool? isCalendarLoading,
    final bool? isSessionsLoading,
    final String? errorMessage,
    final bool clearErrorMessage = false,
  }) => HistoryState(
    selectedDate: selectedDate ?? this.selectedDate,
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: rangeEnd ?? this.rangeEnd,
    calendarStats: calendarStats ?? this.calendarStats,
    sessions: sessions ?? this.sessions,
    isCalendarLoading: isCalendarLoading ?? this.isCalendarLoading,
    isSessionsLoading: isSessionsLoading ?? this.isSessionsLoading,
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required final PuzzleHistoryUseCase historyUseCase})
    : _historyUseCase = historyUseCase,
      super(HistoryState.initial(DateTime.now()));

  static final DateTime _calendarRangeStart = DateTime(2020);
  static final DateTime _calendarRangeEnd = DateTime(2100, 12, 31);

  final PuzzleHistoryUseCase _historyUseCase;

  StreamSubscription<List<CalendarDayStats>>? _calendarSubscription;
  StreamSubscription<List<PuzzleSessionData>>? _sessionsSubscription;

  void initialize({final DateTime? initialDate}) {
    final date = _startOfDay(initialDate ?? DateTime.now());
    emit(
      state.copyWith(
        selectedDate: date,
        rangeStart: _calendarRangeStart,
        rangeEnd: _calendarRangeEnd,
        isCalendarLoading: true,
        isSessionsLoading: true,
        clearErrorMessage: true,
      ),
    );
    _subscribeCalendar();
    _subscribeSessions();
  }

  void selectDate(final DateTime date) {
    final selected = _startOfDay(date);
    if (selected == state.selectedDate) {
      return;
    }
    emit(state.copyWith(selectedDate: selected, isSessionsLoading: true, clearErrorMessage: true));
    _subscribeSessions();
  }

  void _subscribeCalendar() {
    _calendarSubscription?.cancel();
    _calendarSubscription = _historyUseCase
        .watchCalendarStats(state.rangeStart, state.rangeEnd)
        .listen(
          (final calendarStats) => emit(state.copyWith(calendarStats: calendarStats, isCalendarLoading: false)),
          onError: (final error, final stackTrace) {
            emit(state.copyWith(isCalendarLoading: false, errorMessage: error.toString()));
          },
        );
  }

  void _subscribeSessions() {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = _historyUseCase
        .watchSessionsByMonthDay(state.selectedDate)
        .listen(
          (final sessions) => emit(state.copyWith(sessions: sessions, isSessionsLoading: false)),
          onError: (final error, final stackTrace) {
            emit(state.copyWith(isSessionsLoading: false, errorMessage: error.toString()));
          },
        );
  }

  DateTime _startOfDay(final DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Future<void> close() async {
    await _calendarSubscription?.cancel();
    await _sessionsSubscription?.cancel();
    return super.close();
  }
}
