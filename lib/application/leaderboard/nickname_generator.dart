/// Public nickname without user input: "Peter O." from the account name, otherwise "Swift Otter 47" from the uid.
class NicknameGenerator {
  const NicknameGenerator._();

  static const maxLength = 24;
  static const colorCount = 8;

  static String nickname({required final String uid, final String? displayName}) =>
      fromName(displayName) ?? fromUid(uid);

  static int colorIndex(final String uid) => _hash(uid) % colorCount;

  /// Null when the name is empty or looks like an email.
  static String? fromName(final String? displayName) {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty || name.contains('@')) return null;
    final words = name.split(RegExp(r'\s+'));
    final initial = words.length > 1 ? ' ${String.fromCharCode(words.last.runes.first).toUpperCase()}.' : '';
    final first = _truncate(words.first, maxLength - initial.length);
    return '$first$initial';
  }

  static String fromUid(final String uid) {
    final hash = _hash(uid);
    final adjective = _adjectives[hash % _adjectives.length];
    final animal = _animals[(hash ~/ _adjectives.length) % _animals.length];
    final number = 10 + (hash ~/ (_adjectives.length * _animals.length)) % 90;
    return '$adjective $animal $number';
  }

  /// For a narrow table: "Fleet Moose 77" → "FM77"; a name gives three capitals of its first word, "Peter O." → "PET".
  static String shortName(final String nickname) {
    final words = _words(nickname);
    if (words.isEmpty) {
      return '?';
    }
    if (_isGenerated(words)) {
      return '${words[0][0]}${words[1][0]}${words[2]}';
    }
    return String.fromCharCodes(words.first.runes.take(3)).toUpperCase();
  }

  /// [shortName] of each, told apart where they match: a name gets its last initial, then a number.
  static List<String> shortNames(final List<String> nicknames) {
    final codes = [for (final nickname in nicknames) shortName(nickname)];
    final withInitials = [
      for (var i = 0; i < codes.length; i++)
        codes.where((final code) => code == codes[i]).length > 1 ? codes[i] + _lastInitial(nicknames[i]) : codes[i],
    ];
    final seen = <String, int>{};
    return [
      for (final code in withInitials)
        switch (seen.update(code, (final count) => count + 1, ifAbsent: () => 1)) {
          1 => code,
          final count => '$code$count',
        },
    ];
  }

  static List<String> _words(final String value) =>
      value.trim().split(RegExp(r'\s+')).where((final word) => word.isNotEmpty).toList();

  static bool _isGenerated(final List<String> words) =>
      words.length == 3 &&
      _adjectives.contains(words[0]) &&
      _animals.contains(words[1]) &&
      RegExp(r'^\d{2}$').hasMatch(words[2]);

  static String _lastInitial(final String nickname) {
    final words = _words(nickname);
    if (words.length < 2 || _isGenerated(words)) {
      return '';
    }
    return String.fromCharCodes(words.last.runes.take(1)).toUpperCase();
  }

  static String _truncate(final String value, final int length) {
    final runes = value.runes.toList();
    return runes.length <= length ? value : String.fromCharCodes(runes.take(length));
  }

  // 32-bit FNV-1a, stable unlike String.hashCode; the multiply is split to stay exact on the web.
  static int _hash(final String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x193 + (hash & 0xff) * 0x1000000) & 0xffffffff;
    }
    return hash;
  }

  static const _adjectives = [
    'Agile', 'Amber', 'Bold', 'Brave', 'Bright', 'Calm', 'Clever', 'Cosmic', //
    'Crisp', 'Curious', 'Daring', 'Eager', 'Fair', 'Fancy', 'Fleet', 'Gentle',
    'Glad', 'Golden', 'Grand', 'Happy', 'Hidden', 'Honest', 'Jolly', 'Keen',
    'Kind', 'Lucky', 'Lunar', 'Merry', 'Mighty', 'Misty', 'Nimble', 'Noble',
    'Patient', 'Polar', 'Proud', 'Quick', 'Quiet', 'Rapid', 'Royal', 'Rustic',
    'Sharp', 'Shiny', 'Silent', 'Silver', 'Sly', 'Smart', 'Solar', 'Steady',
    'Sunny', 'Swift', 'Tidy', 'Witty', 'Vivid', 'Wild', 'Wise', 'Zesty',
  ];

  static const _animals = [
    'Badger', 'Bear', 'Beaver', 'Bison', 'Crane', 'Crow', 'Deer', 'Dolphin', //
    'Eagle', 'Falcon', 'Ferret', 'Finch', 'Fox', 'Gecko', 'Hare', 'Hawk',
    'Heron', 'Ibex', 'Koala', 'Lark', 'Lemur', 'Lynx', 'Marten', 'Mole',
    'Moose', 'Otter', 'Owl', 'Panda', 'Parrot', 'Pelican', 'Puffin', 'Quail',
    'Rabbit', 'Raven', 'Robin', 'Salmon', 'Seal', 'Sparrow', 'Squirrel', 'Stork',
    'Swan', 'Tiger', 'Toucan', 'Turtle', 'Walrus', 'Whale', 'Wolf', 'Wren',
  ];
}
