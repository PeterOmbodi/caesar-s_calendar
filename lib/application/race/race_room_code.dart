import 'dart:math';

/// Five characters from an alphabet without look-alikes (no 0/O, no 1/I).
abstract final class RaceRoomCode {
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int length = 5;

  static final Uri _webVersion = Uri.parse('https://peterombodi.github.io/caesar-s_calendar/');
  static const String linkParameter = 'race';

  /// Opens the web version with the room's code filled in.
  static Uri link(final String code) => _webVersion.replace(queryParameters: {linkParameter: code});

  static String generate([final Random? random]) {
    final source = random ?? Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < length; i++) alphabet.codeUnitAt(source.nextInt(alphabet.length)),
    ]);
  }

  /// The code as stored, or null when [input] cannot be one. Case, spaces and dashes are forgiven.
  static String? normalize(final String input) {
    final code = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final isValid = code.length == length && code.split('').every(alphabet.contains);
    return isValid ? code : null;
  }
}
