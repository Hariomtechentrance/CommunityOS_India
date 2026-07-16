import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsersService } from './users.service';

// Separate from UsersController (@Controller('users/me')) - this is the
// general "find someone by @username or name" lookup, distinct from the
// caller's own account.
@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
@UseGuards(JwtAuthGuard)
export class UserSearchController {
  constructor(private readonly users: UsersService) {}

  @Get('search')
  search(@Query('q') q: string | undefined, @CurrentUser() currentUser: { userId: string }) {
    return this.users.searchUsers(q ?? '', currentUser.userId);
  }
}
