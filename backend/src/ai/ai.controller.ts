import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AiService } from './ai.service';
import { AskCommunityDto } from './dto/ask-community.dto';
import { TranslateDto } from './dto/translate.dto';

@ApiTags('ai')
@ApiBearerAuth()
@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private readonly ai: AiService) {}

  @Get('status')
  status() {
    return { configured: this.ai.isConfigured };
  }

  // AI calls cost real money per request - throttled tighter than the
  // global default so one user can't run up the bill via a tight retry loop.
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @Post('translate')
  translate(@Body() dto: TranslateDto) {
    return this.ai.translate(dto.text, dto.targetLanguage).then((text) => ({ text }));
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('societies/:societyId/ask')
  ask(@Param('societyId') societyId: string, @Body() dto: AskCommunityDto) {
    return this.ai
      .answerCommunityQuestion(societyId, dto.question)
      .then((answer) => ({ answer }));
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Get('societies/:societyId/summary')
  summary(@Param('societyId') societyId: string) {
    return this.ai.communitySummary(societyId).then((summary) => ({ summary }));
  }
}
