/// Represents a value of one of two possible types (a disjoint union).
/// Instances of [Either] are either an instance of [Left] or [Right].
///
/// Convention dictates that [Left] is used for "failure"
/// and [Right] is used for "success".
sealed class Either<L, R> {
  const Either();

  /// Returns true if this is a [Left]
  bool get isLeft => this is Left<L, R>;

  /// Returns true if this is a [Right]
  bool get isRight => this is Right<L, R>;

  /// Returns the [Left] value or null
  L? get leftOrNull => isLeft ? (this as Left<L, R>).value : null;

  /// Returns the [Right] value or null
  R? get rightOrNull => isRight ? (this as Right<L, R>).value : null;

  /// Fold over the state of the Either
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    if (this is Left<L, R>) {
      return onLeft((this as Left<L, R>).value);
    } else {
      return onRight((this as Right<L, R>).value);
    }
  }
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
}
