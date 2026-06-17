import { SetMetadata } from '@nestjs/common';

export const ALLOWED_TOKEN_TYPES_KEY = 'allowedTokenTypes';

export const AllowTokenTypes = (...types: Array<'access' | 'refresh'>) =>
  SetMetadata(ALLOWED_TOKEN_TYPES_KEY, types);
