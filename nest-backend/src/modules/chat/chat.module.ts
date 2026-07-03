import { Module } from '@nestjs/common';
import { ChatApiModule } from './api/chat-api.module';
import { ChatUseCasesModule } from './usecases/chat-usecases.module';
import { ChatGateway } from './chat.gateway';

@Module({
  imports: [ChatUseCasesModule, ChatApiModule],
  providers: [ChatGateway],
})
export class ChatModule {}
