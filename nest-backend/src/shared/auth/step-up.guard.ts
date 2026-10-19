import { applyDecorators, CanActivate, ExecutionContext, Injectable, SetMetadata, UnauthorizedException, UseGuards } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { AuthUser } from '@/shared/core/types';
import { StepUpPurpose } from './biometric-credential.service';
import { StepUpService } from './step-up.service';

const STEP_UP_REQUIREMENT = 'step-up-requirement';
type Requirement = { purpose: StepUpPurpose; resourceParam?: string };

export function RequireStepUp(purpose: StepUpPurpose, resourceParam?: string): MethodDecorator {
  return applyDecorators(SetMetadata(STEP_UP_REQUIREMENT, { purpose, resourceParam } satisfies Requirement), UseGuards(StepUpGuard));
}

@Injectable()
export class StepUpGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly stepUp: StepUpService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requirement = this.reflector.getAllAndOverride<Requirement>(STEP_UP_REQUIREMENT, [context.getHandler(), context.getClass()]);
    if (!requirement) return true;
    const request = context.switchToHttp().getRequest<Request & { user?: AuthUser }>();
    const userId = request.user?.userId;
    const header = request.headers['x-step-up-token'];
    const token = typeof header === 'string' ? header : undefined;
    const resourceId = requirement.resourceParam ? request.params[requirement.resourceParam] : undefined;
    if (!userId || !token || !await this.stepUp.consume(token, userId, requirement.purpose, resourceId)) {
      throw new UnauthorizedException('Fresh step-up proof required');
    }
    return true;
  }
}
