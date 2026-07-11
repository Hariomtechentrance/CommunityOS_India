import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';

@Module({
  imports: [MembershipsModule],
  controllers: [PostsController],
  providers: [PostsService],
})
export class PostsModule {}
