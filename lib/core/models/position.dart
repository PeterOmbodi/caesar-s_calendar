class Position {
  const Position({required this.dx, required this.dy});

  const Position.zero()
      : dx = 0,
        dy = 0;

  factory Position.fromMap(final Map<String, dynamic> map) => Position(
        dx: (map['dx'] as num).toDouble(),
        dy: (map['dy'] as num).toDouble(),
      );

  Map<String, double> toMap() => {'dx': dx, 'dy': dy};

  Position copyWith({final double? dx, final double? dy}) => Position(
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
      );

  final double dx;
  final double dy;

  @override
  bool operator ==(covariant final Position other) => dx == other.dx && dy == other.dy;

  @override
  int get hashCode => Object.hash(dx, dy);
}
