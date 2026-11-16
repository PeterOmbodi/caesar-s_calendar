const int _mask32 = 0xFFFFFFFF;

/// 32-bit multiplication that stays exact on the web, where ints are doubles.
int imul32(final int a, final int b) {
  final aLo = a & 0xFFFF;
  final aHi = (a >>> 16) & 0xFFFF;
  final bLo = b & 0xFFFF;
  final bHi = (b >>> 16) & 0xFFFF;
  return (aLo * bLo + (((aHi * bLo + aLo * bHi) & 0xFFFF) << 16)) & _mask32;
}

/// mulberry32. `Random(seed)` from `dart:math` gives different sequences on the web and on devices.
class RaceRng {
  RaceRng(final int seed) : _state = seed & _mask32;

  int _state;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = _state;
    t = imul32(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + imul32(t ^ (t >>> 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ (t >>> 14)) & _mask32;
  }

  /// Uniform in `0..max-1`. [max] up to 2^20 keeps the product exact on the web.
  int nextInt(final int max) {
    assert(max > 0 && max <= 1 << 20, 'max out of range: $max');
    return (nextUint32() * max) ~/ 0x100000000;
  }
}
