import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { MessageKind } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SendMessageDto } from './dto/send-message.dto';
import { MessagesGateway } from './messages.gateway';
import { MessagesService } from './messages.service';

@ApiTags('messages')
@ApiBearerAuth()
@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(
    private readonly messages: MessagesService,
    private readonly gateway: MessagesGateway,
  ) {}

  @Get('threads')
  threads(@CurrentUser() user: { userId: string }) {
    return this.messages.listThreads(user.userId);
  }

  @Get('with/:userId')
  thread(@CurrentUser() user: { userId: string }, @Param('userId') otherUserId: string) {
    return this.messages.getThread(user.userId, otherUserId);
  }

  @Post()
  async send(@CurrentUser() user: { userId: string }, @Body() dto: SendMessageDto) {
    const message = await this.messages.send(
      user.userId,
      dto.toUserId,
      dto.body,
      dto.kind as MessageKind | undefined,
    );
    this.gateway.pushToUser(dto.toUserId, message);
    return message;
  }
}
