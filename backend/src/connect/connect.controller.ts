import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ConnectService } from './connect.service';
import { UpdateConnectSettingsDto } from './dto/update-connect-settings.dto';

@ApiTags('connect')
@ApiBearerAuth()
@Controller('connect')
@UseGuards(JwtAuthGuard)
export class ConnectController {
  constructor(private readonly connect: ConnectService) {}

  @Patch('settings')
  updateSettings(@CurrentUser() user: { userId: string }, @Body() dto: UpdateConnectSettingsDto) {
    return this.connect.updateSettings(user.userId, dto);
  }

  // Throttled tighter than the global default - this is a "give me someone
  // to talk to" action a person might tap repeatedly, not a normal GET.
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Get('match')
  findMatch(@CurrentUser() user: { userId: string }) {
    return this.connect.findMatch(user.userId);
  }
}
