import { Module } from '@nestjs/common';
import { CategoryController } from './category.controller';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [CategoryController],
  providers: [PrismaService],
})
export class CategoryModule {}
