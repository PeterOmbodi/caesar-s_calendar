import 'dart:math';

import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated codes have five characters without look-alikes', () {
    final random = Random(1);
    for (var i = 0; i < 500; i++) {
      final code = RaceRoomCode.generate(random);
      expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{5}$')));
      expect(RaceRoomCode.normalize(code), code);
    }
  });

  test('normalize forgives case, spaces and dashes', () {
    expect(RaceRoomCode.normalize(' k7m-4p '), 'K7M4P');
    expect(RaceRoomCode.normalize('K7 M4P'), 'K7M4P');
  });

  test('normalize rejects what cannot be a code', () {
    for (final input in ['', 'K7M4', 'K7M4PQ', 'K0M4P', 'KOM4P', 'K1M4P', 'KIM4P', 'K7M4!']) {
      expect(RaceRoomCode.normalize(input), isNull, reason: input);
    }
  });
}
