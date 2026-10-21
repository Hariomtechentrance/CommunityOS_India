import { ForbiddenException, Injectable } from '@nestjs/common';
import { MessageKind, Prisma } from '@prisma/client';
import { BlocksService } from '../blocks/blocks.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly blocks: BlocksService,
  ) {}

  async send(senderId: string, receiverId: string, body: string, kind?: MessageKind) {
    if (await this.blocks.isBlockedEitherWay(senderId, receiverId)) {
      throw new ForbiddenException('You can\'t message this user');
    }

    // NO_ONE blocks new threads, but doesn't retroactively hide an existing
    // conversation - someone you already messaged while open to DMs can
    // still reply, matching how this control works on other apps.
    const receiver = await this.prisma.user.findUnique({
      where: { id: receiverId },
      select: { allowMessagesFrom: true },
    });
    if (receiver?.allowMessagesFrom === 'NO_ONE') {
      const existingThread = await this.prisma.message.findFirst({
        where: {
          OR: [
            { senderId, receiverId },
            { senderId: receiverId, receiverId: senderId },
          ],
        },
      });
      if (!existingThread) {
        throw new ForbiddenException('This user isn\'t accepting messages right now');
      }
    }

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
   * recently active first. Uses Postgres's DISTINCT ON to get exactly one
   * (the latest) message per conversation partner directly in the database -
   * the previous version pulled this user's ENTIRE message history (every
   * message, every conversation, fully joined) on every single open of the
   * chat list, which only got slower as history grew. This is O(number of
   * conversations), not O(number of messages ever sent).
   */
  async listThreads(userId: string) {
    const latestPerThread = await this.prisma.$queryRaw<
      {
        id: string;
        senderId: string;
        receiverId: string;
        body: string;
        kind: MessageKind;
        createdAt: Date;
        otherUserId: string;
      }[]
    >(Prisma.sql`
      SELECT DISTINCT ON ("otherUserId") *
      FROM (
        SELECT
          m.*,
          CASE WHEN m."senderId" = ${userId} THEN m."receiverId" ELSE m."senderId" END AS "otherUserId"
        FROM "Message" m
        WHERE m."senderId" = ${userId} OR m."receiverId" = ${userId}
      ) sub
      ORDER BY "otherUserId", "createdAt" DESC
    `);

    if (latestPerThread.length === 0) return [];

    const otherUsers = await this.prisma.user.findMany({
      where: { id: { in: latestPerThread.map((m) => m.otherUserId) } },
      select: { id: true, name: true, avatarUrl: true },
    });
    const otherUserById = new Map(otherUsers.map((u) => [u.id, u]));

    return latestPerThread
      .map((m) => ({
        otherUser: otherUserById.get(m.otherUserId),
        lastMessage: m,
      }))
      .filter((t): t is { otherUser: NonNullable<typeof t.otherUser>; lastMessage: typeof t.lastMessage } =>
        !!t.otherUser,
      )
      .sort((a, b) => b.lastMessage.createdAt.getTime() - a.lastMessage.createdAt.getTime());
  }
}
