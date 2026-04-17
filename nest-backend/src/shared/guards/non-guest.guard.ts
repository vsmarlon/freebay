import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';

@Injectable()
export class NonGuestGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (user?.isGuest) {
      throw new ForbiddenException({
        success: false,
        error: {
          code: 'GUEST_FORBIDDEN',
          message: 'Guest users cannot perform this action',
        },
      });
    }

    return true;
  }
}
