import { Injectable } from '@nestjs/common';
import { MessageKind } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  send(senderId: string, receiverId: string, body: string, kind?: MessageKind) {
    return this.prisma.message.create({
      data: { senderId, receiverId, body, kind: kind ?? MessageKind.TEXT },
    });
  }

  getThread(userId: string, otherUserId: string) {
    return this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: userId },
        ],
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * One row per person this user has ever exchanged a message with, most
   * recently active first - kept simple (grouped in application code) since
   * there's no separate Conversation entity at this scale.
   */
  async listThreads(userId: string) {
    const messages = await this.prisma.message.findMany({
      where: { OR: [{ senderId: userId }, { receiverId: userId }] },
      orderBy: { createdAt: 'desc' },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
        receiver: { select: { id: true, name: true, avatarUrl: true } },
      },
    });

    const seen = new Map<
      string,
      {
        otherUser: { id: string; name: string | null; avatarUrl: string | null };
        lastMessage: (typeof messages)[number];
      }
    >();
    for (const message of messages) {
      const otherUser = message.senderId === userId ? message.receiver : message.sender;
      if (!seen.has(otherUser.id)) {
        seen.set(otherUser.id, { otherUser, lastMessage: message });
      }
    }
    return Array.from(seen.values());
  }
}
