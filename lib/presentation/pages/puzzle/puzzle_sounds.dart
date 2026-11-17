import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PuzzleSounds {
  // Android starts low latency playback late, so stopping after the bare clip length cuts the click off.
  static const _stopAfter = Duration(milliseconds: 200);

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

  /// Loads the click ahead of the first move: a sound played right after loading stays silent on Android.
  Future<void> warmUp() async {
    try {
      await _createPool();
    } on Object catch (error) {
      _pool = null;
      debugPrint('Move sound warm up failed: $error');
    }
  }

  Future<void> playClick() async {
    try {
      final pool = await _createPool();
      final stop = await pool.start();
      // Low latency players never complete, so the pool gets them back on stop.
      unawaited(Future<void>.delayed(_stopAfter, stop));
    } on Object catch (error) {
      _pool = null;
      debugPrint('Move sound failed: $error');
    }
  }

  Future<AudioPool> _createPool() => _pool ??= AudioPool.create(
    source: AssetSource('sounds/click.wav'),
    maxPlayers: 4,
    audioContext: _context,
    playerMode: _mode,
  );

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
