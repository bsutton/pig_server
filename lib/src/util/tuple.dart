/// A generic tuple class representing a pair of values.
class Tuple<L, R> {
  /// Creates a tuple with the specified [lhs] and [rhs].
  const Tuple(this.lhs, this.rhs);

  /// The left-hand side value.
  final L lhs;

  /// The right-hand side value.
  final R rhs;
}
