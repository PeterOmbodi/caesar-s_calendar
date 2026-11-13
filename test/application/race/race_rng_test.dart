import 'package:caesar_puzzle/application/race/race_rng.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Reference values of mulberry32; they must hold in the VM and with `--platform chrome`.
  test('fixed seeds give the reference sequences', () {
    const expected = {
      0: [1144304738, 1416247, 958946056],
      1: [2693262067, 11749833, 2265367787],
      0xDEADBEEF: [4043151706, 1147597007, 3315858022],
    };
    for (final MapEntry(key: seed, value: values) in expected.entries) {
      final rng = RaceRng(seed);
      expect([for (var i = 0; i < values.length; i++) rng.nextUint32()], values, reason: 'seed $seed');
    }
  });

  test('imul32 keeps the low 32 bits of the product', () {
    expect(imul32(0xFFFFFFFF, 0xFFFFFFFF), 1);
    expect(imul32(0x811C9DC5, 0x01000193), 0x050C5D1F);
    expect(imul32(123456789, 987654321), 4227814277);
  });

  test('nextInt stays in range and reaches both ends', () {
    final rng = RaceRng(42);
    final seen = {for (var i = 0; i < 2000; i++) rng.nextInt(6)};
    expect(seen, {0, 1, 2, 3, 4, 5});
  });
}
