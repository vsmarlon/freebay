import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UrlSafetyService } from '../services/url-safety.service';
import { UrlSafetyVerification } from '../types/chat.types';

@Injectable()
export class VerifyUrlSafetyUseCase {
  constructor(private readonly urlSafetyService: UrlSafetyService) {}

  async execute(rawUrl: string): Promise<Either<AppError, UrlSafetyVerification>> {
    const result = await this.urlSafetyService.verifyPublicDestination(rawUrl);
    return right(result);
  }
}
