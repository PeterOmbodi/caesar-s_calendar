import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/status/status_for.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/status/status_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => S.load(const Locale('en')));

  test('pieces placed on Hard show the count, not a dead end', () {
    expect(statusText(const PuzzleStatus(StatusMessage.piecesPlaced, count: 3, total: 8)), '3 of 8 placed');
    expect(statusText(const PuzzleStatus(StatusMessage.noSolutions)), 'No solutions · undo a move');
  });
}
