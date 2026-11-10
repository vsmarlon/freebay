import { SetMetadata } from '@nestjs/common';
import { JwtTokenType } from '@/shared/core/types';

export const ALLOWED_TOKEN_TYPES_KEY = 'allowedTokenTypes';

export const AllowTokenTypes = (...types: Array<JwtTokenType>) =>
  SetMetadata(ALLOWED_TOKEN_TYPES_KEY, types);
