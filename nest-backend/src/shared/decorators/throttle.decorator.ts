import { SetMetadata } from '@nestjs/common';

export const SKIP_THROTTLE_KEY = 'skipThrottle';
export const THROTTLE_LIMIT_KEY = 'throttleLimit';
export const THROTTLE_TTL_KEY = 'throttleTtl';

export const SkipThrottle = () => SetMetadata(SKIP_THROTTLE_KEY, true);

export const Throttle = (limit: number, ttl: number) => {
  return (target: object, propertyKey?: string | symbol, descriptor?: PropertyDescriptor) => {
    SetMetadata(THROTTLE_LIMIT_KEY, limit)(target, propertyKey!, descriptor!);
    SetMetadata(THROTTLE_TTL_KEY, ttl)(target, propertyKey!, descriptor!);
  };
};
