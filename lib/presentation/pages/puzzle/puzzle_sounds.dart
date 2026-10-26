import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PuzzleSounds {
  static const _clickLength = Duration(milliseconds: 35);

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static final _mode = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? PlayerMode.lowLatency
      : PlayerMode.mediaPlayer;

  Future<AudioPool>? _pool;

  Future<void> playClick() async {
    try {
      final pool = await (_pool ??= AudioPool.create(
        source: AssetSource('sounds/click.wav'),
        maxPlayers: 3,
        audioContext: _context,
        playerMode: _mode,
      ));
      final stop = await pool.start();
      // Low latency players never complete, so the pool gets them back on stop.
      unawaited(Future<void>.delayed(_clickLength, stop));
    } on Object catch (error) {
      _pool = null;
      debugPrint('Move sound failed: $error');
    }
  }

  Future<void> dispose() async {
    final pool = _pool;
    _pool = null;
    try {
      await (await pool)?.dispose();
    } on Object catch (error) {
      debugPrint('Move sound dispose failed: $error');
    }
  }
}
