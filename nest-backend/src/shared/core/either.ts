import { Failure } from '../errors/failures/failures';

export type Either<L, R> = Left<L, R> | Right<L, R>;

export class Left<L, R = never> {
  readonly value: L;

  constructor(value: L) {
    this.value = value;
  }

  isLeft(): this is Left<L, R> {
    return true;
  }

  isRight(): this is Right<L, R> {
    return false;
  }
}

export class Right<L = never, R = unknown> {
  readonly value: R;

  constructor(value: R) {
    this.value = value;
  }

  isLeft(): this is Left<L, R> {
    return false;
  }

  isRight(): this is Right<L, R> {
    return true;
  }
}

export const left = <L, R = never>(l: L): Either<L, R> => {
  return new Left<L, R>(l);
};

export const right = <L = never, R = unknown>(r: R): Either<L, R> => {
  return new Right<L, R>(r);
};

export type RepositoryResponse<T, F = Failure> = Promise<Either<F, T>>;
