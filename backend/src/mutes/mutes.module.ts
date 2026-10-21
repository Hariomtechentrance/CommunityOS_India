import { Module } from '@nestjs/common';
import { MutesController } from './mutes.controller';
import { MutesService } from './mutes.service';

// No AuthModule import - same reasoning as BlocksModule: JwtAuthGuard has
// no injected dependencies, it resolves Passport's global 'jwt' strategy.
@Module({
  controllers: [MutesController],
  providers: [MutesService],
  exports: [MutesService],
})
export class MutesModule {}
