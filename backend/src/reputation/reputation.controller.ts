import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ReputationService } from './reputation.service';

@ApiTags('reputation')
@ApiBearerAuth()
@Controller()
@UseGuards(JwtAuthGuard)
export class ReputationController {
  constructor(private readonly reputation: ReputationService) {}

  @Get('users/:userId/reputation')
  getReputation(@Param('userId') userId: string) {
    return this.reputation.getReputation(userId);
  }
}
