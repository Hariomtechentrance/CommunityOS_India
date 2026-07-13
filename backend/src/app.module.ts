import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SocietiesModule } from './societies/societies.module';
import { MembershipsModule } from './memberships/memberships.module';
import { NoticesModule } from './notices/notices.module';
import { ComplaintsModule } from './complaints/complaints.module';
import { PostsModule } from './posts/posts.module';
import { PollsModule } from './polls/polls.module';
import { EventsModule } from './events/events.module';
import { ListingsModule } from './listings/listings.module';
import { AreaModule } from './area/area.module';
import { CallsModule } from './calls/calls.module';
import { LiveModule } from './live/live.module';
import { MessagesModule } from './messages/messages.module';
import { StoriesModule } from './stories/stories.module';
import { TurnModule } from './turn/turn.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    SocietiesModule,
    MembershipsModule,
    NoticesModule,
    ComplaintsModule,
    PostsModule,
    PollsModule,
    EventsModule,
    ListingsModule,
    AreaModule,
    CallsModule,
    LiveModule,
    MessagesModule,
    StoriesModule,
    TurnModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
