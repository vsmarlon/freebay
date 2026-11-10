import { Module } from '@nestjs/common';
import { ChatUseCasesModule } from './usecases/chat-usecases.module';
import { ChatGateway } from './chat.gateway';
import { ChatController } from './chat.controller';

@Module({
  imports: [ChatUseCasesModule],
  controllers: [ChatController],
  providers: [ChatGateway],
  exports: [ChatUseCasesModule, ChatGateway],
})
export class ChatModule {}
