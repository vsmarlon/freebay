import { Controller, Get, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '@/shared/decorators/public.decorator';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RedisService } from '@/shared/infra/redis/redis.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Get()
  @Public()
  @HttpCode(HttpStatus.OK)
  async check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'freebay-backend',
    };
  }

  @Get('ready')
  @Public()
  @HttpCode(HttpStatus.OK)
  async readiness() {
    let dbStatus = 'healthy';
    let redisStatus = 'healthy';

    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = 'unhealthy';
    }

    try {
      const ping = await this.redis.ping();
      if (ping !== 'PONG') redisStatus = 'unhealthy';
    } catch {
      redisStatus = 'unhealthy';
    }

    const isHealthy = dbStatus === 'healthy' && redisStatus === 'healthy';

    return {
      status: isHealthy ? 'ready' : 'degraded',
      checks: {
        database: dbStatus,
        redis: redisStatus,
      },
      timestamp: new Date().toISOString(),
    };
  }
}
