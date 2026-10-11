import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/infrastructure/persistence/config_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Standard placements hash to the Standard config id', () {
    expect(configIdFor(PuzzleConfigJson.encode(PuzzleConfigJson.standardPlacements)), StandardPuzzleConfig.id);
  });

  test('decode reverses encode', () {
    final placements = [PlacementParams('zone1', 2, 6, 1, false), PlacementParams('zone2', 0, 1, 3, true)];
    final decoded = PuzzleConfigJson.decode(PuzzleConfigJson.encode(placements));
    expect(
      [for (final p in decoded) (p.pieceId, p.row, p.col, p.rotationSteps, p.isFlipped)],
      [('zone1', 2, 6, 1, false), ('zone2', 0, 1, 3, true)],
    );
  });
}
