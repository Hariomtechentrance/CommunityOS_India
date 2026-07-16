import { Module } from '@nestjs/common';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { UserSearchController } from './user-search.controller';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [GeocodingModule],
  controllers: [UsersController, UserSearchController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
