/// A helper class representing a cell (grid coordinate) on the board.
class Cell {

  Cell(this.row, this.col);

  factory Cell.fromMap(final Map<String, dynamic> map) =>
      Cell(map['row'], map['col']);
  final int row;
  final int col;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is Cell && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Cell($row, $col)';

  Map<String, dynamic> toMap() => {
    'row': row,
    'col': col,
  };
}