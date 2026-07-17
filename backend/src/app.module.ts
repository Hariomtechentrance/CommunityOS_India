import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { FollowsModule } from './follows/follows.module';
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
import { PlacesModule } from './places/places.module';
import { StoriesModule } from './stories/stories.module';
import { TurnModule } from './turn/turn.module';
import { ReelsModule } from './reels/reels.module';
import { CampaignsModule } from './campaigns/campaigns.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Global request-rate ceiling - a generous default so normal browsing
    // never trips it, with individual endpoints free to set tighter limits
    // via @Throttle() (auth, campaign creation/checkout, search).
    ThrottlerModule.forRoot([
      { name: 'default', ttl: 60_000, limit: 120 },
    ]),
    PrismaModule,
    AdminModule,
    AuthModule,
    UsersModule,
    FollowsModule,
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
    PlacesModule,
    StoriesModule,
    TurnModule,
    ReelsModule,
    CampaignsModule,
  ],
  controllers: [AppController],
  providers: [AppService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
