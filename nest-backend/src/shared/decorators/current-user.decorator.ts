import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthUser } from '../core/types';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): AuthUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user as AuthUser;
  },
);
