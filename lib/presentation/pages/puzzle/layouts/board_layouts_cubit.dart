import 'dart:async';

import 'package:caesar_puzzle/application/contracts/board_layout_repository.dart';
import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LayoutEntry {
  LayoutEntry(this.layout) : blocked = blockedCellsOf(layout.placements) {
    key = cellsKey(blocked);
  }

  final BoardLayout layout;
  final Set<Cell> blocked;
  late final String key;
}

typedef SolutionCounter = Future<int> Function(List<PlacementParams> placements, DateTime date);

class BoardLayoutsState {
  const BoardLayoutsState({this.entries = const [], this.solutionCounts = const {}});

  final List<LayoutEntry> entries;
  final Map<String, int> solutionCounts;

  LayoutEntry? entryWithKey(final String key) => entries.firstWhereOrNull((final e) => e.key == key);

  int? solutionsFor(final LayoutEntry entry, final DateTime date) => solutionCounts[_countKey(entry, date)];

  BoardLayoutsState copyWith({final List<LayoutEntry>? entries, final Map<String, int>? solutionCounts}) =>
      BoardLayoutsState(entries: entries ?? this.entries, solutionCounts: solutionCounts ?? this.solutionCounts);
}

String _countKey(final LayoutEntry entry, final DateTime date) => '${date.year}-${date.month}-${date.day}|${entry.key}';

class BoardLayoutsCubit extends Cubit<BoardLayoutsState> {
  BoardLayoutsCubit(this._repository) : super(const BoardLayoutsState()) {
    _subscription = _repository.watchLayouts().listen(
      (final layouts) => emit(state.copyWith(entries: [for (final layout in layouts) LayoutEntry(layout)])),
    );
  }

  final BoardLayoutRepository _repository;
  late final StreamSubscription<List<BoardLayout>> _subscription;
  final _counting = <String>{};

  Future<void> countSolutions(final Iterable<LayoutEntry> entries, final DateTime date, final SolutionCounter count) async {
    for (final entry in entries) {
      final key = _countKey(entry, date);
      if (state.solutionCounts.containsKey(key) || !_counting.add(key)) {
        continue;
      }
      final solutions = await count(entry.layout.placements, date);
      _counting.remove(key);
      if (isClosed) {
        return;
      }
      emit(state.copyWith(solutionCounts: {...state.solutionCounts, key: solutions}));
    }
  }

  Future<void> save(final String name, final List<PlacementParams> placements) =>
      _repository.saveLayout(name: name, placements: placements);

  Future<void> rename(final BoardLayout layout, final String name) => _repository.renameLayout(layout.id, name);

  Future<void> delete(final BoardLayout layout) => _repository.deleteLayout(layout.id);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
