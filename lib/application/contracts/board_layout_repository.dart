import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

abstract class BoardLayoutRepository {
  Stream<List<BoardLayout>> watchLayouts();

  /// Standard placements are not saved; their id is returned.
  Future<String> saveLayout({required String name, required List<PlacementParams> placements});

  Future<void> renameLayout(String id, String name);

  Future<void> deleteLayout(String id);
}
