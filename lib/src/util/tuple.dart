/// A generic tuple class representing a pair of values.
class Tuple<L, R> {
  /// The left-hand side value.
  final L lhs;

  /// The right-hand side value.
  final R rhs;

  /// Creates a tuple with the specified [lhs] and [rhs].
  const Tuple(this.lhs, this.rhs);
}
