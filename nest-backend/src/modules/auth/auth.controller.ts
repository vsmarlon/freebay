import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDTO, LoginDTO, LogoutDTO, UsernameAvailabilityQueryDTO } from './dtos/auth.dto';
import {
  RequestPasswordRecoveryDTO,
  VerifyPasswordRecoveryCodeDTO,
  ResetPasswordDTO,
} from './dtos/password-recovery.dto';
import {
  AuthSessionResponse,
  GuestSessionResponse,
  TokenRefreshResponse,
  MessageResponse,
} from './dtos/auth-response.class';
import { Public } from '@/shared/decorators/public.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthUser } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { AllowTokenTypes } from './guards/token-types.decorator';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly jwtService: JwtService,
  ) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } })
  @ApiDoc({
    summary: 'Register new user',
    description: 'Creates account and returns JWT access + refresh tokens',
    bodyType: RegisterDTO,
    responseType: AuthSessionResponse,
    responseStatus: 201,
    errors: [{ status: 409, description: 'Email already exists' }],
  })
  @Public()
  async register(@Body() body: RegisterDTO) {
    return this.authService.register(body);
  }

  @Get('username-available')
  @Throttle({ short: { limit: 10, ttl: 10000 }, medium: { limit: 60, ttl: 60000 } })
  @ApiDoc({
    summary: 'Check username availability',
    description: 'Returns whether a username is valid and not already taken',
  })
  @Public()
  async usernameAvailable(@Query() query: UsernameAvailabilityQueryDTO) {
    return this.authService.checkUsernameAvailability(query);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: 10, ttl: 60000 }, medium: { limit: 30, ttl: 60000 } })
  @ApiDoc({
    summary: 'Login',
    description: 'Authenticate with email and password',
    bodyType: LoginDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid credentials' }],
  })
  @Public()
  async login(@Body() body: LoginDTO) {
    return this.authService.login(body);
  }

  @Post('guest')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } })
  @ApiDoc({
    summary: 'Create guest session',
    description: 'Creates temporary guest user and returns JWT token',
    responseType: GuestSessionResponse,
  })
  @Public()
  async guest() {
    return this.authService.guest();
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Refresh token',
    description: 'Exchanges a valid refresh token for a new access + refresh token pair',
    auth: true,
    responseType: TokenRefreshResponse,
  })
  @AllowTokenTypes('refresh')
  async refresh(@CurrentUser() user: AuthUser) {
    return this.authService.refresh(user);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Logout',
    description: 'Blacklists current JWT tokens',
    auth: true,
    responseType: MessageResponse,
  })
  async logout(@CurrentUser() user: AuthUser, @Body() body?: LogoutDTO) {
    let refreshPayload: { jti: string; exp: number } | undefined;
    if (body?.refreshToken) {
      try {
        const payload = await this.jwtService.verifyAsync<AuthUser>(body.refreshToken, {
          secret: process.env.JWT_SECRET,
        });
        if (payload.type === 'refresh' && payload.userId === user.userId) {
          refreshPayload = { jti: payload.jti!, exp: payload.exp! };
        }
      } catch { void 0; }
    }
    return this.authService.logout({ jti: user.jti, exp: user.exp }, refreshPayload);
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Request password recovery',
    description: 'Sends password recovery code to the given email',
    bodyType: RequestPasswordRecoveryDTO,
  })
  @Public()
  async forgotPassword(@Body() body: RequestPasswordRecoveryDTO) {
    return this.authService.forgotPassword(body);
  }

  @Post('verify-reset-code')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Verify password recovery code',
    description: 'Checks if the 6-digit recovery code is valid',
    bodyType: VerifyPasswordRecoveryCodeDTO,
  })
  @Public()
  async verifyResetCode(@Body() body: VerifyPasswordRecoveryCodeDTO) {
    return this.authService.verifyResetCode(body);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Reset password',
    description: 'Resets password using verified recovery code',
    bodyType: ResetPasswordDTO,
  })
  @Public()
  async resetPassword(@Body() body: ResetPasswordDTO) {
    return this.authService.resetPassword(body);
  }
}
