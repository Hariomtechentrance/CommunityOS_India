import { Body, Controller, Get, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DetectAreaDto } from './dto/detect-area.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { UpdateFcmTokenDto } from './dto/update-fcm-token.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users/me')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  me(@CurrentUser() user: { userId: string }) {
    return this.users.findById(user.userId);
  }

  @Patch('location')
  updateLocation(
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateLocationDto,
  ) {
    return this.users.updateLocation(user.userId, dto);
  }

  @Post('detect-area')
  detectArea(@Body() dto: DetectAreaDto) {
    return this.users.detectArea(dto.lat, dto.lng);
  }

  @Get('neighbours')
  neighbours(@CurrentUser() user: { userId: string }, @Query('area') area: string) {
    return this.users.listNeighbours(area, user.userId);
  }

  @Patch('fcm-token')
  updateFcmToken(@CurrentUser() user: { userId: string }, @Body() dto: UpdateFcmTokenDto) {
    return this.users.updateFcmToken(user.userId, dto.token);
  }

  @Patch('avatar')
  updateAvatar(@CurrentUser() user: { userId: string }, @Body() dto: UpdateAvatarDto) {
    return this.users.updateAvatar(user.userId, dto.avatarUrl);
  }
}
