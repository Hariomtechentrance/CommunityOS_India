import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { LiveGateway } from './live.gateway';

@ApiTags('live')
@ApiBearerAuth()
@Controller('live-streams')
@UseGuards(JwtAuthGuard)
export class LiveController {
  constructor(private readonly live: LiveGateway) {}

  @Get()
  list(@Query('area') area: string) {
    return this.live.listActive(area);
  }
}
