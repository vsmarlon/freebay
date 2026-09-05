import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UrlSafetyService, UrlSafetyVerification } from '../services/url-safety.service';

@Injectable()
export class VerifyUrlSafetyUseCase {
  constructor(private readonly urlSafetyService: UrlSafetyService) {}

  async execute(rawUrl: string): Promise<Either<AppError, UrlSafetyVerification>> {
    const result = this.urlSafetyService.verifyUrl(rawUrl);
    return right(result);
  }
}
