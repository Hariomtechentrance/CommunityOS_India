import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsersService } from '../users/users.service';
import { CampaignsService } from './campaigns.service';
import { CreateCampaignDto } from './dto/create-campaign.dto';

@ApiTags('campaigns')
@Controller('campaigns')
export class CampaignsController {
  constructor(
    private readonly campaigns: CampaignsService,
    private readonly users: UsersService,
  ) {}

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateCampaignDto) {
    return this.campaigns.create(user.userId, dto);
  }

  @Get('mine')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  listMine(@CurrentUser() user: { userId: string }) {
    return this.campaigns.listMine(user.userId);
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post(':id/checkout')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  checkout(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.campaigns.checkout(id, user.userId);
  }

  @Get('feed')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  async feed(@CurrentUser() user: { userId: string }, @Query('area') _area?: string) {
    const viewer = await this.users.findById(user.userId);
    return this.campaigns.feedFor({
      pincode: viewer?.pincode,
      state: viewer?.state,
      latitude: viewer?.latitude,
      longitude: viewer?.longitude,
    });
  }

  // Public - Razorpay calls this directly, verified by HMAC signature, not
  // a user session. Needs the raw request body (see main.ts rawBody: true).
  @Post('webhook/razorpay')
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-razorpay-signature') signature: string | undefined,
  ) {
    return this.campaigns.handleWebhook(req.rawBody ?? Buffer.from(''), signature);
  }
}
