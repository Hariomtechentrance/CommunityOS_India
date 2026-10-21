import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CoinTransactionType, PayoutStatus } from '@prisma/client';
import { RazorpayService } from '../campaigns/razorpay.service';
import { PrismaService } from '../prisma/prisma.service';

// ₹1 = 10 coins, flat - simplest possible MVP pricing, no package catalog
// to design/maintain. Trivial to swap for tiered packages later.
const COINS_PER_RUPEE = 10;
const MIN_PURCHASE_PAISE = 1000; // ₹10 minimum, keeps Razorpay fees sane relative to the amount.
const MIN_PAYOUT_COINS = 500; // ₹50 - keeps admin payout overhead reasonable relative to the amount.

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly razorpay: RazorpayService,
    private readonly config: ConfigService,
  ) {}

  private async getOrCreateWallet(userId: string) {
    const existing = await this.prisma.wallet.findUnique({ where: { userId } });
    if (existing) return existing;
    try {
      return await this.prisma.wallet.create({ data: { userId } });
    } catch {
      // Lost a create race - someone else's request created it first.
      return this.prisma.wallet.findUniqueOrThrow({ where: { userId } });
    }
  }

  async getBalance(userId: string) {
    const wallet = await this.getOrCreateWallet(userId);
    const transactions = await this.prisma.coinTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return { balanceCoins: wallet.balanceCoins, transactions };
  }

  async purchase(userId: string, amountInPaise: number) {
    if (amountInPaise < MIN_PURCHASE_PAISE) {
      throw new BadRequestException(`Minimum purchase is ₹${MIN_PURCHASE_PAISE / 100}`);
    }
    const wallet = await this.getOrCreateWallet(userId);
    const coinsAmount = Math.floor((amountInPaise / 100) * COINS_PER_RUPEE);

    const appUrl = this.config.get<string>('APP_URL') ?? 'https://community-os-india.web.app';
    const link = await this.razorpay.createPaymentLink({
      amountInPaise,
      description: `${coinsAmount} Niikat Coins`,
      referenceId: `coins-${wallet.id}-${Date.now()}`,
      callbackUrl: `${appUrl}/#/home/wallet`,
    });

    await this.prisma.coinPurchase.create({
      data: {
        walletId: wallet.id,
        coinsAmount,
        priceInPaise: amountInPaise,
        razorpayLinkId: link.id,
      },
    });

    return { checkoutUrl: link.short_url };
  }

  /** Razorpay calls this directly - verified purely by the webhook's HMAC
   * signature over the raw body, same as CampaignsService.handleWebhook. */
  async handleWebhook(rawBody: Buffer, signature: string | undefined) {
    if (!this.razorpay.verifyWebhookSignature(rawBody, signature)) {
      throw new ForbiddenException('Invalid webhook signature');
    }

    const payload = JSON.parse(rawBody.toString('utf8'));
    if (payload.event !== 'payment_link.paid') return { received: true };

    const linkId = payload.payload?.payment_link?.entity?.id as string | undefined;
    const paymentId = payload.payload?.payment?.entity?.id as string | undefined;
    if (!linkId) return { received: true };

    const purchase = await this.prisma.coinPurchase.findUnique({ where: { razorpayLinkId: linkId } });
    // Not ours - some other product's Razorpay link (e.g. a campaign payment).
    if (!purchase || purchase.status === 'paid') return { received: true };

    await this.prisma.$transaction([
      this.prisma.coinPurchase.update({
        where: { id: purchase.id },
        data: { status: 'paid', razorpayPaymentId: paymentId },
      }),
      this.prisma.coinTransaction.create({
        data: {
          walletId: purchase.walletId,
          type: CoinTransactionType.PURCHASE,
          amount: purchase.coinsAmount,
          description: `Purchased ${purchase.coinsAmount} coins`,
        },
      }),
      this.prisma.wallet.update({
        where: { id: purchase.walletId },
        data: { balanceCoins: { increment: purchase.coinsAmount } },
      }),
    ]);
    return { received: true };
  }

  /** Send coins to another user - a tip/gift, not a cash transfer (coins
   * never leave the closed loop). The debit uses a conditional update
   * (balance >= amount) checked inside the same transaction as the credit,
   * so two concurrent gifts from one wallet can't both pass a stale
   * pre-check and overdraw it - updateMany's count is the atomic guard. */
  async gift(fromUserId: string, toUserId: string, amount: number, description?: string) {
    if (fromUserId === toUserId) throw new ForbiddenException("You can't gift yourself");
    if (amount <= 0) throw new BadRequestException('Amount must be positive');

    const toUser = await this.prisma.user.findUnique({ where: { id: toUserId } });
    if (!toUser) throw new NotFoundException('Recipient not found');

    const fromWallet = await this.getOrCreateWallet(fromUserId);
    const toWallet = await this.getOrCreateWallet(toUserId);

    await this.prisma.$transaction(async (tx) => {
      const debited = await tx.wallet.updateMany({
        where: { id: fromWallet.id, balanceCoins: { gte: amount } },
        data: { balanceCoins: { decrement: amount } },
      });
      if (debited.count === 0) {
        throw new BadRequestException('Not enough coins');
      }
      await tx.wallet.update({
        where: { id: toWallet.id },
        data: { balanceCoins: { increment: amount } },
      });
      await tx.coinTransaction.create({
        data: {
          walletId: fromWallet.id,
          type: CoinTransactionType.GIFT_SENT,
          amount: -amount,
          relatedUserId: toUserId,
          description,
        },
      });
      await tx.coinTransaction.create({
        data: {
          walletId: toWallet.id,
          type: CoinTransactionType.GIFT_RECEIVED,
          amount,
          relatedUserId: fromUserId,
          description,
        },
      });
    });

    return this.getBalance(fromUserId);
  }

  /** Creator cashes out earned coins (e.g. from gifts) as real money. Coins
   * are deducted immediately on request (same atomic-update guard as
   * `gift`) so a user can't request more than they hold; actual money
   * movement happens outside this app when an admin marks the request PAID
   * after sending a real bank/UPI transfer - see PayoutRequest's schema
   * comment for why that step isn't automated. */
  async requestPayout(
    userId: string,
    amountCoins: number,
    payeeName: string,
    upiId?: string,
    bankAccountNumber?: string,
    bankIfsc?: string,
  ) {
    if (amountCoins < MIN_PAYOUT_COINS) {
      throw new BadRequestException(
        `Minimum payout is ${MIN_PAYOUT_COINS} coins (₹${MIN_PAYOUT_COINS / COINS_PER_RUPEE})`,
      );
    }
    if (!upiId && !(bankAccountNumber && bankIfsc)) {
      throw new BadRequestException('Provide either a UPI ID or a bank account number + IFSC');
    }

    const wallet = await this.getOrCreateWallet(userId);

    return this.prisma.$transaction(async (tx) => {
      const debited = await tx.wallet.updateMany({
        where: { id: wallet.id, balanceCoins: { gte: amountCoins } },
        data: { balanceCoins: { decrement: amountCoins } },
      });
      if (debited.count === 0) {
        throw new BadRequestException('Not enough coins');
      }
      await tx.coinTransaction.create({
        data: {
          walletId: wallet.id,
          type: CoinTransactionType.PAYOUT,
          amount: -amountCoins,
          description: 'Payout requested',
        },
      });
      return tx.payoutRequest.create({
        data: {
          walletId: wallet.id,
          userId,
          amountCoins,
          amountInPaise: Math.floor((amountCoins / COINS_PER_RUPEE) * 100),
          payeeName,
          upiId,
          bankAccountNumber,
          bankIfsc,
        },
      });
    });
  }

  listMyPayouts(userId: string) {
    return this.prisma.payoutRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listPayoutRequests(status: PayoutStatus | undefined, page: number, pageSize: number) {
    const where = status ? { status } : undefined;
    const [items, total] = await Promise.all([
      this.prisma.payoutRequest.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true, avatarUrl: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.payoutRequest.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  /** Rejecting refunds the held coins back to the wallet; approving/paying
   * just updates status - the actual transfer is the admin's own manual
   * bank/UPI action, see requestPayout's doc comment. */
  async setPayoutStatus(id: string, status: PayoutStatus, adminNote?: string) {
    const payout = await this.prisma.payoutRequest.findUniqueOrThrow({ where: { id } });

    if (status === PayoutStatus.REJECTED && payout.status !== PayoutStatus.REJECTED) {
      await this.prisma.$transaction([
        this.prisma.wallet.update({
          where: { id: payout.walletId },
          data: { balanceCoins: { increment: payout.amountCoins } },
        }),
        this.prisma.coinTransaction.create({
          data: {
            walletId: payout.walletId,
            type: CoinTransactionType.PAYOUT,
            amount: payout.amountCoins,
            description: 'Payout rejected - refunded',
          },
        }),
        this.prisma.payoutRequest.update({
          where: { id },
          data: { status, adminNote, processedAt: new Date() },
        }),
      ]);
      return this.prisma.payoutRequest.findUniqueOrThrow({ where: { id } });
    }

    return this.prisma.payoutRequest.update({
      where: { id },
      data: { status, adminNote, processedAt: status !== PayoutStatus.PENDING ? new Date() : undefined },
    });
  }
}
