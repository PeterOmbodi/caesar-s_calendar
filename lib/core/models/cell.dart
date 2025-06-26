/// A helper class representing a cell (grid coordinate) on the board.
class Cell {
  final int row;
  final int col;

  Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cell && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Cell($row, $col)';

  factory Cell.fromMap(Map<String, dynamic> map) =>
      Cell(map['row'], map['col']);

  Map<String, dynamic> toMap() => {
    'row': row,
    'col': col,
  };
}