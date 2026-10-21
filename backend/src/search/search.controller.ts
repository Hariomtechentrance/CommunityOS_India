import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsersService } from '../users/users.service';
import { SearchService } from './search.service';

@ApiTags('search')
@ApiBearerAuth()
@Controller('search')
@UseGuards(JwtAuthGuard)
export class SearchController {
  constructor(
    private readonly search: SearchService,
    private readonly users: UsersService,
  ) {}

  @Get()
  async searchAll(@Query('q') q: string, @CurrentUser() user: { userId: string }) {
    const viewer = await this.users.findById(user.userId);
    return this.search.searchAll(q, user.userId, viewer?.area);
  }
}
