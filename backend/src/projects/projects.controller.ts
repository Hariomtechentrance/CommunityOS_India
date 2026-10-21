import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateProjectUpdateDto } from './dto/create-project-update.dto';
import { CreateProjectDto } from './dto/create-project.dto';
import { ProjectsService } from './projects.service';

@ApiTags('projects')
@ApiBearerAuth()
@Controller()
@UseGuards(JwtAuthGuard)
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @Post('projects')
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateProjectDto) {
    return this.projects.create(user.userId, dto);
  }

  @Get('users/:userId/projects')
  listForUser(@Param('userId') userId: string) {
    return this.projects.listForUser(userId);
  }

  @Get('projects/:id')
  findOne(@Param('id') id: string) {
    return this.projects.findOne(id);
  }

  @Post('projects/:id/updates')
  addUpdate(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateProjectUpdateDto,
  ) {
    return this.projects.addUpdate(id, user.userId, dto);
  }

  @Delete('projects/:id')
  delete(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.projects.delete(id, user.userId);
  }
}
