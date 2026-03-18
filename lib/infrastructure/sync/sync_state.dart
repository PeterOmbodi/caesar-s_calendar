enum SyncState {
  clean(0),
  dirty(1),
  syncing(2),
  error(3);

  const SyncState(this.code);
  final int code;

  static SyncState fromCode(final int code) =>
      SyncState.values.firstWhere((final s) => s.code == code, orElse: () => SyncState.clean);
}

