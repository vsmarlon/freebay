import { Controller, HttpCode, HttpStatus, Logger, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { GetPublic } from '@/shared/decorators';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RedisService } from '@/shared/infra/redis/redis.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  private readonly logger = new Logger(HealthController.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @GetPublic({ summary: 'Health check' })
  @HttpCode(HttpStatus.OK)
  async check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'freebay-backend',
    };
  }

  @GetPublic('ready', {
    summary: 'Readiness check',
    description: 'Returns 503 when a dependency is unavailable so probes can act on the status code',
  })
  async readiness(@Res() response: Response) {
    let dbStatus = 'healthy';
    let redisStatus = 'healthy';

    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch (error) {
      dbStatus = 'unhealthy';
      this.logger.error(`Readiness: database unreachable — ${(error as Error).message}`);
    }

    try {
      const ping = await this.redis.ping();
      if (ping !== 'PONG') {
        redisStatus = 'unhealthy';
        this.logger.error(`Readiness: redis replied '${ping}' instead of PONG`);
      }
    } catch (error) {
      redisStatus = 'unhealthy';
      this.logger.error(`Readiness: redis unreachable — ${(error as Error).message}`);
    }

    const isHealthy = dbStatus === 'healthy' && redisStatus === 'healthy';

    response
      .status(isHealthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE)
      .json({
        status: isHealthy ? 'ready' : 'degraded',
        checks: {
          database: dbStatus,
          redis: redisStatus,
        },
        timestamp: new Date().toISOString(),
      });
  }
}
