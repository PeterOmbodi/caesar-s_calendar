import 'package:flutter/foundation.dart';

@immutable
class SyncStatus {
  const SyncStatus({
    required this.isSyncing,
    required this.lastSuccessAtMs,
    required this.lastError,
  });

  factory SyncStatus.initial() => const SyncStatus(isSyncing: false, lastSuccessAtMs: null, lastError: null);

  final bool isSyncing;
  final int? lastSuccessAtMs;
  final String? lastError;

  SyncStatus copyWith({
    final bool? isSyncing,
    final int? lastSuccessAtMs,
    final String? lastError,
    final bool clearError = false,
  }) => SyncStatus(
    isSyncing: isSyncing ?? this.isSyncing,
    lastSuccessAtMs: lastSuccessAtMs ?? this.lastSuccessAtMs,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

