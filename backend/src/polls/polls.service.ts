import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePollDto } from './dto/create-poll.dto';

@Injectable()
export class PollsService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, authorId: string, dto: CreatePollDto) {
    return this.prisma.poll.create({
      data: {
        societyId,
        authorId,
        question: dto.question,
        options: { create: dto.options.map((label) => ({ label })) },
      },
      include: { options: true },
    });
  }

  async listForSociety(societyId: string, currentUserId: string) {
    const polls = await this.prisma.poll.findMany({
      where: { societyId },
      include: {
        author: true,
        options: { include: { _count: { select: { votes: true } } } },
        votes: { where: { userId: currentUserId } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return polls.map((poll) => ({
      ...poll,
      myVoteOptionId: poll.votes[0]?.pollOptionId ?? null,
      votes: undefined,
    }));
  }

  async vote(societyId: string, pollId: string, userId: string, optionId: string) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.societyId !== societyId) {
      throw new NotFoundException('Poll not found');
    }

    const option = await this.prisma.pollOption.findUnique({ where: { id: optionId } });
    if (!option || option.pollId !== pollId) {
      throw new BadRequestException('Option does not belong to this poll');
    }

    return this.prisma.pollVote.upsert({
      where: { pollId_userId: { pollId, userId } },
      update: { pollOptionId: optionId },
      create: { pollId, userId, pollOptionId: optionId },
    });
  }
}
