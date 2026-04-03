class ExactCoverProblem<C extends Object, R extends Object> {
  ExactCoverProblem({
    required final Set<C> primaryColumns,
    final Set<C> secondaryColumns = const {},
    required final Map<R, Set<C>> rows,
  }) : primaryColumns = Set.unmodifiable(primaryColumns),
       secondaryColumns = Set.unmodifiable(secondaryColumns),
       rows = Map.unmodifiable({
         for (final entry in rows.entries) entry.key: Set.unmodifiable(entry.value),
       }) {
    final duplicateColumns = this.primaryColumns.intersection(this.secondaryColumns);
    if (duplicateColumns.isNotEmpty) {
      throw ArgumentError.value(
        duplicateColumns,
        'secondaryColumns',
        'Primary and secondary columns must be disjoint.',
      );
    }

    final knownColumns = allColumns;
    for (final entry in this.rows.entries) {
      if (entry.value.isEmpty) {
        throw ArgumentError.value(entry.key, 'rows', 'Each row must cover at least one column.');
      }

      final unknownColumns = entry.value.difference(knownColumns);
      if (unknownColumns.isNotEmpty) {
        throw ArgumentError.value(
          unknownColumns,
          'rows',
          'Each row may only reference declared columns.',
        );
      }
    }
  }

  factory ExactCoverProblem.withPrimaryColumns({
    required final Set<C> columns,
    required final Map<R, Set<C>> rows,
  }) => ExactCoverProblem(primaryColumns: columns, rows: rows);

  final Set<C> primaryColumns;
  final Set<C> secondaryColumns;
  final Map<R, Set<C>> rows;

  Set<C> get allColumns => {...primaryColumns, ...secondaryColumns};
}
