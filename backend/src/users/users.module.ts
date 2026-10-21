import { Module } from '@nestjs/common';
import { BlocksModule } from '../blocks/blocks.module';
import { firebaseAdminProvider } from '../auth/firebase-admin.provider';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { UserSearchController } from './user-search.controller';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  // firebaseAdminProvider (not AuthModule) deliberately, to avoid a
  // circular dependency - AuthModule already imports UsersModule.
  imports: [GeocodingModule, BlocksModule],
  controllers: [UsersController, UserSearchController],
  providers: [UsersService, firebaseAdminProvider],
  exports: [UsersService],
})
export class UsersModule {}
