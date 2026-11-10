import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { MediaAccessService } from './services/media-access.service';
import { AuthModule } from '@/modules/auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [MediaController],
  providers: [MediaAccessService],
})
export class MediaModule {}
