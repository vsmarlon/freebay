import { Controller, Get, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../infra/prisma/prisma.service';
import { RedisService } from '../infra/redis/redis.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  @Get()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Health check' })
  async check() {
    const checks: Record<string, string> = {};

    try {
      await this.prisma.$queryRaw`SELECT 1`;
      checks.database = 'ok';
    } catch {
      checks.database = 'error';
    }

    try {
      await this.redis.ping();
      checks.redis = 'ok';
    } catch {
      checks.redis = 'error';
    }

    const allOk = Object.values(checks).every((s) => s === 'ok');

    return {
      status: allOk ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      checks,
    };
  }
}
