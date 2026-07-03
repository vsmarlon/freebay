import { Module } from '@nestjs/common';
import { ChatController } from '../chat.controller';
import { ChatService } from './chat.service';
import { ChatUseCasesModule } from '../usecases/chat-usecases.module';

@Module({
  imports: [ChatUseCasesModule],
  controllers: [ChatController],
  providers: [ChatService],
  exports: [ChatService],
})
export class ChatApiModule {}
