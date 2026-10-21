import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CloudinaryService } from './cloudinary.service';

@ApiTags('media')
@ApiBearerAuth()
@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly cloudinary: CloudinaryService) {}

  // One signature is good for one upload (tied to its timestamp) - throttled
  // generously since a multi-photo post legitimately needs several in quick
  // succession, but still bounded.
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Get('cloudinary-signature')
  getSignature() {
    return this.cloudinary.generateSignature();
  }
}
