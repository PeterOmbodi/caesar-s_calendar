import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LayoutService();

  LayoutConfig layoutFor(final Size size, {final double? maxCell}) => service.buildInitialLayout(
    Offset.zero & size,
    maxCell: maxCell ?? ScreenSpec(size: size, family: ChromeFamily.glass).maxCell,
  );

  group('cell size cap per window class', () {
    test('compact phone portrait is not affected by the cap', () {
      const size = Size(393, 800);
      final capped = layoutFor(size);
      final uncapped = layoutFor(size, maxCell: double.infinity);
      expect(capped.gridConfig.cellSize, uncapped.gridConfig.cellSize);
      expect(capped.gridConfig.cellSize, lessThan(ScreenSpec.compactMaxCell));
    });

    test('compact phone landscape is not affected by the cap', () {
      const size = Size(852, 340);
      final capped = layoutFor(size);
      final uncapped = layoutFor(size, maxCell: double.infinity);
      expect(capped.gridConfig.cellSize, uncapped.gridConfig.cellSize);
    });

    test('medium tablet portrait is capped at 72', () {
      const size = Size(1032, 1300);
      expect(layoutFor(size, maxCell: double.infinity).gridConfig.cellSize, greaterThan(ScreenSpec.mediumMaxCell));

      final layout = layoutFor(size);
      expect(layout.gridConfig.cellSize, ScreenSpec.mediumMaxCell);
      expect(layout.boardConfig.cellSize, ScreenSpec.mediumMaxCell * LayoutService.boardToGridSizeRatio);
    });

    test('expanded tablet landscape is capped at 80', () {
      const size = Size(1376, 980);
      expect(layoutFor(size, maxCell: double.infinity).gridConfig.cellSize, greaterThan(ScreenSpec.expandedMaxCell));
      expect(layoutFor(size).gridConfig.cellSize, ScreenSpec.expandedMaxCell);
    });

    test('cell size stays even when the cap is odd', () {
      expect(layoutFor(const Size(1032, 1300), maxCell: 57).gridConfig.cellSize, 56);
    });
  });

  group('content rect', () {
    test('layout is offset by the content rect origin', () {
      const size = Size(393, 800);
      final atZero = service.buildInitialLayout(Offset.zero & size, maxCell: ScreenSpec.compactMaxCell);
      final shifted = service.buildInitialLayout(const Offset(20, 60) & size, maxCell: ScreenSpec.compactMaxCell);

      expect(shifted.gridConfig.cellSize, atZero.gridConfig.cellSize);
      expect(shifted.gridConfig.origin.dx, closeTo(atZero.gridConfig.origin.dx + 20, 1e-9));
      expect(shifted.gridConfig.origin.dy, closeTo(atZero.gridConfig.origin.dy + 60, 1e-9));
      expect(shifted.boardConfig.origin.dx, closeTo(atZero.boardConfig.origin.dx + 20, 1e-9));
      expect(shifted.boardConfig.origin.dy, closeTo(atZero.boardConfig.origin.dy + 60, 1e-9));
    });

    test('rebuildLayout applies the cap of the new window class', () {
      final phone = layoutFor(const Size(393, 800));
      final tablet = service.rebuildLayout(
        contentRect: Offset.zero & const Size(1032, 1300),
        maxCell: ScreenSpec.mediumMaxCell,
        prevGrid: phone.gridConfig,
        prevBoard: phone.boardConfig,
        pieces: phone.pieces,
      );
      expect(tablet.gridConfig.cellSize, ScreenSpec.mediumMaxCell);
      expect(tablet.pieces.length, phone.pieces.length);
    });
  });
}
