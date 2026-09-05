import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetPublic } from '@/shared/decorators';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RedisService } from '@/shared/infra/redis/redis.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @GetPublic({ summary: 'Health check' })
  async check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'freebay-backend',
    };
  }

  @GetPublic('ready', { summary: 'Readiness check' })
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
