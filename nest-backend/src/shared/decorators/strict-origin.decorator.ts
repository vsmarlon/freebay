import { SetMetadata } from '@nestjs/common';

export const STRICT_ORIGIN_KEY = 'strictOrigin';
// ponytail: marks cookie-auth/web entry points that must present a trusted Origin.
export const StrictOrigin = () => SetMetadata(STRICT_ORIGIN_KEY, true);
