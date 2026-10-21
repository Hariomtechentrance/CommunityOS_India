import { Module } from '@nestjs/common';
import { BlocksController } from './blocks.controller';
import { BlocksService } from './blocks.service';

// Deliberately doesn't import AuthModule - JwtAuthGuard has no injected
// dependencies of its own; it resolves the 'jwt' Passport strategy from the
// process-global registry that AuthModule populates once at app root, not
// through Nest's per-module DI. Importing AuthModule here would create a
// cycle (AuthModule -> UsersModule -> BlocksModule -> AuthModule), since
// UsersModule depends on this module for blocked-user filtering.
@Module({
  controllers: [BlocksController],
  providers: [BlocksService],
  exports: [BlocksService],
})
export class BlocksModule {}
