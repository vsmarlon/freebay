sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;

  bool get isRight => this is Right<L, R>;

  L? get leftOrNull => isLeft ? (this as Left<L, R>).value : null;

  R? get rightOrNull => isRight ? (this as Right<L, R>).value : null;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    if (this is Left<L, R>) {
      return onLeft((this as Left<L, R>).value);
    } else {
      return onRight((this as Right<L, R>).value);
    }
  }

  R getOrElse(R Function() dflt) => fold((_) => dflt(), (r) => r);
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;

  @override
  bool operator ==(Object other) => other is Left && other.value == value;

  @override
  int get hashCode => Object.hash('Left', value);
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;

  @override
  bool operator ==(Object other) => other is Right && other.value == value;

  @override
  int get hashCode => Object.hash('Right', value);
}

extension EitherExtensions<L, R> on Either<L, R> {
  R? unwrapOrHandle(void Function(L error) onError) {
    if (isLeft) {
      onError((this as Left<L, R>).value);
      return null;
    }
    return (this as Right<L, R>).value;
  }

  void when({
    void Function(L failure)? onError,
    void Function(R data)? onSuccess,
  }) {
    if (isLeft) {
      onError?.call((this as Left<L, R>).value);
    } else {
      onSuccess?.call((this as Right<L, R>).value);
    }
  }
}
