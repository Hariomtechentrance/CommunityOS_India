import { Module } from '@nestjs/common';
import { SocietiesModule } from '../societies/societies.module';
import { UsersModule } from '../users/users.module';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

@Module({
  imports: [UsersModule, SocietiesModule],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
