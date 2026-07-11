import { Injectable } from '@nestjs/common';
import { Either, left } from '@/shared/core/either';
import { AppError, NotImplementedError } from '@/shared/core/errors';

@Injectable()
export class RegisterBankAccountUseCase {
  async execute(_input: {
    userId: string;
    bankCode: string;
    accountNumber: string;
    accountCheckDigit: string;
    branchNumber: string;
    branchCheckDigit: string;
    holderName: string;
    holderDocument: string;
  }): Promise<Either<AppError, void>> {
    return left(new NotImplementedError('PagBank recipient registration'));
  }
}
