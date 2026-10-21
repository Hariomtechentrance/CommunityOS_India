import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SocietyType } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateSocietyDto } from './dto/create-society.dto';
import { SocietiesService } from './societies.service';

@ApiTags('societies')
@Controller('societies')
export class SocietiesController {
  constructor(private readonly societies: SocietiesService) {}

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateSocietyDto) {
    return this.societies.create(user.userId, dto);
  }

  @Get()
  search(
    @Query('q') q?: string,
    @Query('pincode') pincode?: string,
    @Query('type') type?: SocietyType,
  ) {
    return this.societies.search(q, pincode, type);
  }

  @Get(':societyId')
  findOne(@Param('societyId') societyId: string) {
    return this.societies.findById(societyId);
  }
}
