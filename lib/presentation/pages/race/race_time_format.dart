/// `1:42`, or `1:42.3` with [tenths], for a race time in milliseconds.
String formatRaceTime(final int milliseconds, {final bool tenths = false}) {
  final ms = milliseconds < 0 ? 0 : milliseconds;
  final minutes = ms ~/ 60000;
  final seconds = '${ms ~/ 1000 % 60}'.padLeft(2, '0');
  return tenths ? '$minutes:$seconds.${ms ~/ 100 % 10}' : '$minutes:$seconds';
}
