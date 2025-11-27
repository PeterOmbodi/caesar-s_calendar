
/// Node for Dancing Links.
/// Each node is linked to its neighbors in four directions,
/// and also stores a reference to its column (if it's not a header node).
class DlxNode {
  // name of the row (subset), if applicable

  DlxNode() {
    left = this;
    right = this;
    up = this;
    down = this;
  }
  late DlxNode left;
  late DlxNode right;
  late DlxNode up;
  late DlxNode down;
  DlxColumn? column; // for non-header nodes
  String? subsetName;
}

/// Column header node for Dancing Links, extends DlxNode.
/// Stores the column name and the count of nodes (ones) in the column.
class DlxColumn extends DlxNode {
  DlxColumn(this.name) : super();
  int size = 0;
  final String name;
}

/// Class implementing Dancing Links for solving the exact cover problem.
/// The interface: create a universe from a list of column names, add rows (subsets)
/// via [addRow], and then call [search] to find all solutions.
class DlxUniverse {
  /// Constructs a universe from a list of column names.
  DlxUniverse(final List<String> columnNames) : header = DlxColumn('HEADER') {
    DlxNode prev = header;
    for (final name in columnNames) {
      final col = DlxColumn(name);
      // Insert the column to the right of [prev].
      col.left = prev;
      col.right = header;
      prev.right = col;
      header.left = col;
      // Initialize vertical pointers (empty column: up/down point to itself)
      col.up = col;
      col.down = col;
      prev = col;
      columnMap[name] = col;
    }
  }
  final DlxColumn header;
  final List<String> solution = []; // current partial solution
  final List<List<String>> solutions = []; // all found solutions
  final Map<String, DlxColumn> columnMap = {};

  /// Adds a row (subset) with the given [rowName] and a list of column names
  /// where the row contains a 1.
  void addRow(final String rowName, final List<String> columns) {
    DlxNode? firstNode;
    for (final colName in columns) {
      final dCol = columnMap[colName];
      if (dCol == null) {
        // debugPrint("Column '$colName' not found in universe columns. Available: ${columnMap.keys.toList()}");
        continue;
      }
      final newNode = DlxNode();
      newNode.column = dCol;
      newNode.subsetName = rowName;
      // Insert the new node at the bottom of column [dCol] (just above its header).
      newNode.down = dCol;
      newNode.up = dCol.up;
      dCol.up.down = newNode;
      dCol.up = newNode;
      dCol.size++;

      if (firstNode == null) {
        firstNode = newNode;
        newNode.left = newNode;
        newNode.right = newNode;
      } else {
        // Insert the new node in the row (linking it horizontally).
        newNode.right = firstNode;
        newNode.left = firstNode.left;
        firstNode.left.right = newNode;
        firstNode.left = newNode;
      }
    }
  }

  /// Covers a column: removes the column from the structure and
  /// all rows that contain this column.
  void cover(final DlxColumn col) {
    // Remove the column from the list of columns.
    col.right.left = col.left;
    col.left.right = col.right;
    // For each node in column [col], remove the entire row.
    for (var i = col.down; i != col; i = i.down) {
      for (var j = i.right; j != i; j = j.right) {
        j.down.up = j.up;
        j.up.down = j.down;
        j.column!.size--;
      }
    }
  }

  /// Uncovers a previously covered column, restoring it back into the structure.
  void uncover(final DlxColumn col) {
    // Restore rows in reverse order.
    for (var i = col.up; i != col; i = i.up) {
      for (var j = i.left; j != i; j = j.left) {
        j.column!.size++;
        j.down.up = j;
        j.up.down = j;
      }
    }
    col.right.left = col;
    col.left.right = col;
  }

  /// Chooses the column with the smallest number of nodes (heuristic).
  DlxColumn chooseColumn() {
    var chosen = header.right as DlxColumn;
    var minSize = chosen.size;
    for (var col = header.right; col != header; col = col.right) {
      final dCol = col as DlxColumn;
      if (dCol.size < minSize) {
        chosen = dCol;
        minSize = dCol.size;
        if (minSize == 0) break;
      }
    }
    return chosen;
  }

  /// Recursive search for all solutions.
  void _search() {
    // If no columns remain, a complete solution has been found.
    if (header.right == header) {
      if (solutions.indexWhere((final e) => e.join('#') == solution.join('#')) == -1) {
        solutions.add(List.from(solution));
      }
      return;
    }
    // Choose a column using the heuristic.
    final col = chooseColumn();
    cover(col);
    // For each row in the chosen column...
    for (var r = col.down; r != col; r = r.down) {
      // Add the row name (subset name) to the current solution.
      solution.add(r.subsetName!);
      // Cover all columns for the current row.
      for (var j = r.right; j != r; j = j.right) {
        cover(j.column!);
      }
      _search();
      // Backtrack: remove the last row from the current solution.
      solution.removeLast();
      // Uncover columns in reverse order.
      for (var j = r.left; j != r; j = j.left) {
        uncover(j.column!);
      }
    }
    uncover(col);
  }

  /// Initiates the search for all exact cover solutions.
  void search() {
    _search();
  }
}
