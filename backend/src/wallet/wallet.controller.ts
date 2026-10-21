import { Body, Controller, Get, Headers, Post, Req, UseGuards } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { GiftCoinsDto } from './dto/gift-coins.dto';
import { PurchaseCoinsDto } from './dto/purchase-coins.dto';
import { RequestPayoutDto } from './dto/request-payout.dto';
import { WalletService } from './wallet.service';

@ApiTags('wallet')
@Controller('wallet')
export class WalletController {
  constructor(private readonly wallet: WalletService) {}

  @Get()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  getBalance(@CurrentUser() user: { userId: string }) {
    return this.wallet.getBalance(user.userId);
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('purchase')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  purchase(@CurrentUser() user: { userId: string }, @Body() dto: PurchaseCoinsDto) {
    return this.wallet.purchase(user.userId, dto.amountInPaise);
  }

  @Post('gift')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  gift(@CurrentUser() user: { userId: string }, @Body() dto: GiftCoinsDto) {
    return this.wallet.gift(user.userId, dto.toUserId, dto.amount, dto.description);
  }

  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('payouts')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  requestPayout(@CurrentUser() user: { userId: string }, @Body() dto: RequestPayoutDto) {
    return this.wallet.requestPayout(
      user.userId,
      dto.amountCoins,
      dto.payeeName,
      dto.upiId,
      dto.bankAccountNumber,
      dto.bankIfsc,
    );
  }

  @Get('payouts')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  listMyPayouts(@CurrentUser() user: { userId: string }) {
    return this.wallet.listMyPayouts(user.userId);
  }

  // Public - Razorpay calls this directly, verified by HMAC signature, not a
  // user session. Needs the raw request body (see main.ts rawBody: true).
  // NOTE: register this exact URL (<APP_URL>/wallet/webhook/razorpay) as a
  // second webhook endpoint in the Razorpay Dashboard - it's separate from
  // the existing /campaigns/webhook/razorpay one.
  @Post('webhook/razorpay')
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-razorpay-signature') signature: string | undefined,
  ) {
    return this.wallet.handleWebhook(req.rawBody ?? Buffer.from(''), signature);
  }
}
