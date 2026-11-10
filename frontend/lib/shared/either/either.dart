sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;

  bool get isRight => this is Right<L, R>;

  L? get leftOrNull => fold<L?>((left) => left, (_) => null);

  R? get rightOrNull => fold<R?>((_) => null, (right) => right);

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return switch (this) {
      Left<L, R>(value: final value) => onLeft(value),
      Right<L, R>(value: final value) => onRight(value),
    };
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
    return fold((error) {
      onError(error);
      return null;
    }, (data) => data);
  }

  void when({
    void Function(L failure)? onError,
    void Function(R data)? onSuccess,
  }) {
    fold((failure) => onError?.call(failure), (data) => onSuccess?.call(data));
  }
}
