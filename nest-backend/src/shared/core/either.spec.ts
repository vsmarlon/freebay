import { Either, left, Left, right, Right } from './either';
import { AppError, type Failure } from './errors';

describe('Either', () => {
  it('deve retornar sucessos quando for Left', () => {
    const either: Either<Failure, boolean> = left(new AppError('DEFAULT_FAILURE', 'Default failure'));
    expect(either).toBeInstanceOf(Left);
    expect(either.isLeft()).toBeTruthy();
    expect(either.isRight()).toBeFalsy();
    expect(either.value).toBeDefined();
    expect(either.value).toBeInstanceOf(AppError);
  });

  it('deve retornar sucessos quando for Right', () => {
    const either: Either<Failure, boolean> = right(true);
    expect(either).toBeInstanceOf(Right);
    expect(either.isRight()).toBeTruthy();
    expect(either.isLeft()).toBeFalsy();
    expect(either.value).toBeDefined();
    expect(either.value).toBeTruthy();
  });

  it('isRight typechecking', () => {
    const either: Either<Failure, { name: string; age: number }> = right({ name: 'Teste', age: 36 });
    if (either.isRight()) {
      expect(either.value).toMatchObject({
        name: 'Teste',
        age: 36,
      });
    }
  });

  it('isLeft typechecking', () => {
    const either: Either<Failure, { name: string; age: number }> = left(new AppError('DEFAULT_FAILURE', 'Default failure'));
    if (either.isLeft()) {
      expect(either.value).toBeInstanceOf(AppError);
    }
  });
});
