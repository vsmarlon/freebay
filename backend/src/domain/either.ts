export type Either<L, R> = Left<L> | Right<R>;

export class Left<L> {
  readonly _tag = 'left' as const;
  constructor(readonly value: L) {}
}

export class Right<R> {
  readonly _tag = 'right' as const;
  constructor(readonly value: R) {}
}

export const left = <L, R = never>(value: L): Either<L, R> => new Left(value);
export const right = <R, L = never>(value: R): Either<L, R> => new Right(value);

export const isLeft = <L, R>(either: Either<L, R>): either is Left<L> => either._tag === 'left';

export const isRight = <L, R>(either: Either<L, R>): either is Right<R> => either._tag === 'right';
