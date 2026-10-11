import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

abstract class BoardLayoutRepository {
  Stream<List<BoardLayout>> watchLayouts();

  /// Standard placements are not saved; their id is returned.
  Future<String> saveLayout({required final String name, required final List<PlacementParams> placements});

  Future<void> renameLayout(final String id, final String name);

  Future<void> deleteLayout(final String id);
}
