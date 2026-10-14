import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LayoutService();

  LayoutConfig layoutFor(final Size size, {final double? maxCell}) {
    final spec = ScreenSpec(size: size, family: ChromeFamily.glass);
    return service.buildInitialLayout(
      Offset.zero & size,
      maxCell: maxCell ?? spec.maxCell,
      trayScale: spec.trayScale,
      fillAvailableTray: spec.isLandscape ? spec.window == WindowClass.compact : spec.window != WindowClass.compact,
    );
  }

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
      expect(layout.boardConfig.cellSize, ScreenSpec.mediumMaxCell);
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

  group('tray', () {
    test('tablet portrait enlarges the tray and raises the centered board', () {
      final layout = layoutFor(const Size(1032, 1300));
      final grid = layout.gridConfig.getBounds;
      final tray = layout.boardConfig.getBounds;
      expect(layout.boardConfig.cellSize, 72);
      expect(grid.top, 174);
      expect(grid.center.dx, 516);
      expect(tray.center.dx, grid.center.dx);
      expect(tray.top - grid.bottom, 16);
      for (final piece in layout.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
        expect(piece.scale, 1);
      }
    });

    test('short tablet portrait limits tray growth to the remaining height', () {
      final layout = layoutFor(const Size(600, 800));
      expect(layout.boardConfig.cellSize, greaterThan(layout.gridConfig.cellSize * 0.75));
      expect(layout.boardConfig.cellSize, lessThan(layout.gridConfig.cellSize));
      expect(layout.gridConfig.getBounds.top, greaterThanOrEqualTo(0));
      expect(layout.boardConfig.getBounds.bottom, closeTo(800, 1e-9));
    });

    test('phone landscape uses the left edge and matches the combined tray height to the board', () {
      final layout = layoutFor(const Size(852, 330));
      expect(layout.gridConfig.origin.dx, 8);
      expect(layout.boardConfig.cellSize, 46);
      for (final piece in layout.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
        expect(piece.scale, 1);
      }
    });

    test('narrow landscape fits enlarged pieces between the board and right edge', () {
      final layout = layoutFor(const Size(480, 330));
      expect(layout.gridConfig.origin.dx, 8);
      expect(layout.boardConfig.cellSize, greaterThan(layout.gridConfig.cellSize * 0.7));
      expect(layout.boardConfig.getBounds.height + 28, lessThanOrEqualTo(layout.gridConfig.getBounds.height));
      expect(layout.boardConfig.getBounds.right, lessThanOrEqualTo(472));
    });

    test('rotating to landscape and back preserves tray positions and restores scale', () {
      final portrait = layoutFor(const Size(393, 640));
      final landscape = service.rebuildLayout(
        contentRect: const Offset(24, 60) & const Size(852, 330),
        fillAvailableTray: true,
        maxCell: ScreenSpec.compactMaxCell,
        prevGrid: portrait.gridConfig,
        prevBoard: portrait.boardConfig,
        pieces: portrait.pieces,
      );
      expect(landscape.gridConfig.origin.dx, 32);
      expect(landscape.boardConfig.cellSize, 46);
      final restored = service.rebuildLayout(
        contentRect: Offset.zero & const Size(393, 640),
        maxCell: ScreenSpec.compactMaxCell,
        prevGrid: landscape.gridConfig,
        prevBoard: landscape.boardConfig,
        pieces: landscape.pieces,
      );
      for (final before in portrait.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
        final enlarged = landscape.pieces.firstWhere((final p) => p.id == before.id);
        expect(enlarged.scale, 1);
        final after = restored.pieces.firstWhere((final p) => p.id == before.id);
        expect(after.scale, ScreenSpec.compactTrayScale);
        expect((after.position - before.position).distance, closeTo(0, 1e-9));
      }
    });

    test('phone portrait gets the 52 pt board cell from the mockup', () {
      expect(layoutFor(const Size(393, 640)).gridConfig.cellSize, 52);
    });

    test('tray is 7×6 cells at tray scale', () {
      final layout = layoutFor(const Size(393, 640));
      final tray = layout.boardConfig;
      expect(tray.cellSize, layout.gridConfig.cellSize * ScreenSpec.compactTrayScale);
      expect((tray.columns, tray.rows), (LayoutService.trayColumns, LayoutService.trayRows));
    });

    for (final size in [const Size(393, 640), const Size(852, 330), const Size(1032, 1300)]) {
      test('initial tray pieces use the tray scale and stay inside the tray at $size', () {
        final layout = layoutFor(size);
        final trayBounds = layout.boardConfig.getBounds.inflate(0.01);
        final trayPieces = layout.pieces.where((final p) => p.placeZone == PlaceZone.board).toList();
        expect(trayPieces, hasLength(LayoutService.traySlots.length));
        for (final piece in trayPieces) {
          expect(piece.scale, layout.boardConfig.cellSize / layout.gridConfig.cellSize);
          final bounds = piece.getTransformedPath().getBounds();
          expect(
            trayBounds.contains(bounds.topLeft) && trayBounds.contains(bounds.bottomRight),
            isTrue,
            reason: piece.id,
          );
        }
      });
    }

    test('rebuildLayout keeps tray pieces at the same place within the tray', () {
      final phone = layoutFor(const Size(393, 640));
      final tablet = service.rebuildLayout(
        contentRect: Offset.zero & const Size(1032, 1300),
        maxCell: ScreenSpec.mediumMaxCell,
        prevGrid: phone.gridConfig,
        prevBoard: phone.boardConfig,
        pieces: phone.pieces,
        trayScale: ScreenSpec.tabletTrayScale,
        fillAvailableTray: true,
      );
      for (final before in phone.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
        final after = tablet.pieces.firstWhere((final p) => p.id == before.id);
        final relBefore = phone.boardConfig.relativePosition(before.position);
        final relAfter = tablet.boardConfig.relativePosition(after.position);
        expect(relAfter.dx, closeTo(relBefore.dx, 1e-9), reason: before.id);
        expect(relAfter.dy, closeTo(relBefore.dy, 1e-9), reason: before.id);
        expect(after.scale, 1, reason: before.id);
      }
    });
  });

  group('tray area', () {
    for (final size in [const Size(480, 330), const Size(852, 330), const Size(1024, 768), const Size(1376, 980)]) {
      test('landscape tray and status align with both board edges at $size', () {
        final layout = layoutFor(size);
        final grid = layout.gridConfig.getBounds;
        final tray = layout.boardConfig.getBounds;
        expect(grid.left, 8);
        expect(tray.left, closeTo(grid.right + 16, 1e-9));
        expect(tray.right, closeTo(size.width - 8, 1e-9));
        expect(tray.top, closeTo(grid.top, 1e-9));
        expect(tray.bottom + 28, closeTo(grid.bottom, 1e-9));
        expect(layout.boardConfig.cellSize, lessThanOrEqualTo(layout.gridConfig.cellSize));
        for (final piece in layout.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
          expect(piece.scale, lessThanOrEqualTo(1));
        }
        expect(tray.left - grid.right, greaterThanOrEqualTo(16));
        expect(tray.right, lessThanOrEqualTo(size.width - 8));
        expect(grid.top, greaterThanOrEqualTo(0));
        expect(grid.bottom, lessThanOrEqualTo(size.height));
      });
    }

    for (final sizes in [
      (const Size(393, 640), const Size(852, 330)),
      (const Size(1032, 1300), const Size(1376, 980)),
    ]) {
      test('rotation keeps the packed arrangement at ${sizes.$2}', () {
        final portrait = layoutFor(sizes.$1);
        final expected = layoutFor(sizes.$2);
        final spec = ScreenSpec(size: sizes.$2, family: ChromeFamily.glass);
        final rotated = service.rebuildLayout(
          contentRect: Offset.zero & sizes.$2,
          maxCell: spec.maxCell,
          trayScale: spec.trayScale,
          prevGrid: portrait.gridConfig,
          prevBoard: portrait.boardConfig,
          pieces: portrait.pieces,
        );
        for (final piece in expected.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
          final after = rotated.pieces.firstWhere((final p) => p.id == piece.id);
          expect((after.position - piece.position).distance, closeTo(0, 0.001), reason: piece.id);
        }
      });
    }

    for (final size in [const Size(393, 640), const Size(1032, 1300)]) {
      test('portrait tray extends to the bottom of the available content at $size', () {
        final layout = layoutFor(size);
        expect(layout.boardConfig.getBounds.left, 8);
        expect(layout.boardConfig.getBounds.right, closeTo(size.width - 8, 1e-9));
        expect(layout.boardConfig.getBounds.bottom, closeTo(size.height, 1e-9));
        expect(layout.boardConfig.getBounds.top - layout.gridConfig.getBounds.bottom, 16);
        expect(layout.boardConfig.cellSize, lessThanOrEqualTo(layout.gridConfig.cellSize));
      });
    }

    test('wide landscape centers the initial pieces within the expanded tray', () {
      final layout = layoutFor(const Size(1376, 980));
      final pieces = layout.pieces.where((final p) => p.placeZone == PlaceZone.board);
      final bounds = pieces
          .map((final p) => p.getTransformedPath().getBounds())
          .reduce((final a, final b) => a.expandToInclude(b));
      expect(bounds.center.dx, closeTo(layout.boardConfig.getBounds.center.dx, 1e-9));
      expect(bounds.width, lessThan(layout.boardConfig.getBounds.width));
    });

    test('shrinking a wide tray keeps pieces inside the new tray', () {
      final wide = layoutFor(const Size(1376, 980));
      final narrow = service.rebuildLayout(
        contentRect: Offset.zero & const Size(480, 330),
        maxCell: ScreenSpec.compactMaxCell,
        fillAvailableTray: true,
        prevGrid: wide.gridConfig,
        prevBoard: wide.boardConfig,
        pieces: wide.pieces,
      );
      final tray = narrow.boardConfig.getBounds.inflate(0.01);
      for (final piece in narrow.pieces.where((final p) => p.placeZone == PlaceZone.board)) {
        final bounds = piece.getTransformedPath().getBounds();
        expect(tray.contains(bounds.topLeft) && tray.contains(bounds.bottomRight), isTrue, reason: piece.id);
        expect(piece.scale, lessThanOrEqualTo(1));
      }
    });

    for (final size in [
      const Size(393, 640),
      const Size(852, 330),
      const Size(600, 800),
      const Size(768, 850),
      const Size(1032, 1300),
      const Size(1180, 700),
    ]) {
      test('holds the tray and stays clear of the board at $size', () {
        final layout = layoutFor(size);
        final area = layout.trayArea;
        final tray = layout.boardConfig.getBounds;
        expect(area.contains(tray.topLeft) && area.contains(tray.bottomRight - const Offset(0.01, 0.01)), isTrue);
        expect(area.overlaps(layout.gridConfig.getBounds), isFalse);
      });
    }
  });
}
