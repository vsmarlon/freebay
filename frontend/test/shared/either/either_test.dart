import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/either/either.dart';

void main() {
  test('fold and nullable accessors select only the matching side', () {
    const left = Left<String, int>('failure');
    const right = Right<String, int>(42);

    expect(
      left.fold((value) => 'L:$value', (value) => 'R:$value'),
      'L:failure',
    );
    expect(right.fold((value) => 'L:$value', (value) => 'R:$value'), 'R:42');
    expect(left.leftOrNull, 'failure');
    expect(left.rightOrNull, isNull);
    expect(right.leftOrNull, isNull);
    expect(right.rightOrNull, 42);
  });

  test('when and unwrapOrHandle preserve the selected value', () {
    const left = Left<String, int>('failure');
    const right = Right<String, int>(42);
    final errors = <String>[];
    final values = <int>[];

    expect(left.unwrapOrHandle(errors.add), isNull);
    expect(right.unwrapOrHandle(errors.add), 42);
    left.when(onError: errors.add, onSuccess: values.add);
    right.when(onError: errors.add, onSuccess: values.add);

    expect(errors, ['failure', 'failure']);
    expect(values, [42]);
  });
}
