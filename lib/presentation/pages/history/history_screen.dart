import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/pages/history/bloc/history_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/history_screen_result.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_app_bar.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/history_content_layout.dart';
import 'package:caesar_puzzle/presentation/pages/history/widgets/puzzle_day_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  Widget build(final BuildContext context) => BlocProvider(
    create: (_) => HistoryCubit(historyUseCase: getIt<PuzzleHistoryUseCase>())..initialize(initialDate: initialDate),
    child: const _HistoryScaffold(),
  );
}

class _HistoryScaffold extends StatefulWidget {
  const _HistoryScaffold();

  @override
  State<_HistoryScaffold> createState() => _HistoryScaffoldState();
}

class _HistoryScaffoldState extends State<_HistoryScaffold> {
  int _activeTab = 0;
  int _centerSelectionRequest = 0;

  Future<void> _pickDate(final DateTime selectedDate) async {
    final picked = await showPuzzleDayPicker(context, selectedDate: selectedDate);
    if (!mounted || picked == null) {
      return;
    }
    context.read<HistoryCubit>().selectDate(picked);
    setState(() => _centerSelectionRequest++);
  }

  @override
  Widget build(final BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (final context, final state) => Scaffold(
      appBar: HistoryAppBar(onPickDate: () => _pickDate(state.selectedDate)),
      body: SafeArea(
        child: HistoryContentLayout(
          state: state,
          activeTab: _activeTab,
          onTabChanged: (final tab) => setState(() => _activeTab = tab),
          centerSelectionRequest: _centerSelectionRequest,
          onStartPuzzle: (final date) => Navigator.of(context).pop(HistoryScreenResult.startPuzzleForDate(date)),
          onResumeSession: (final session) => Navigator.of(context).pop(HistoryScreenResult.resumeSession(session)),
        ),
      ),
    ),
  );
}
