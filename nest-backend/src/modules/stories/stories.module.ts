import { Module } from '@nestjs/common';
import { StoriesApiModule } from './api/stories-api.module';

@Module({
  imports: [StoriesApiModule],
})
export class StoriesModule {}
