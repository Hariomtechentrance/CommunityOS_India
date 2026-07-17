import { Inject, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { Server, Socket } from 'socket.io';
import { FIREBASE_ADMIN } from '../auth/firebase-admin.provider';
import { PrismaService } from '../prisma/prisma.service';
import { corsOptions } from '../common/socket-cors';

/**
 * Pure signaling relay for in-app calling - no media ever passes through the
 * server, only WebRTC offer/answer/ICE payloads, keyed by the caller's/
 * callee's authenticated `userId`. That identity comes from a JWT verified
 * at connection time (`handshake.auth.token`), not from anything the client
 * claims in a message payload - otherwise any client could register as, and
 * receive calls for, an arbitrary other user. If the target user isn't
 * currently connected, the caller gets `call:unavailable` AND, if the target
 * has a push token, a missed-call notification is sent so they can call back
 * once they open the app - previously this case reached nobody at all.
 */
@WebSocketGateway({ cors: corsOptions })
export class CallsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(CallsGateway.name);

  @WebSocketServer()
  server: Server;

  private readonly profileToSocket = new Map<string, string>();
  private readonly socketToProfile = new Map<string, string>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: App | null,
  ) {}

  handleConnection(client: Socket) {
    const token = client.handshake.auth?.token as string | undefined;
    if (!token) {
      client.disconnect(true);
      return;
    }
    try {
      const payload = this.jwt.verify<{ sub: string }>(token);
      this.profileToSocket.set(payload.sub, client.id);
      this.socketToProfile.set(client.id, payload.sub);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const profileId = this.socketToProfile.get(client.id);
    if (profileId) {
      this.profileToSocket.delete(profileId);
      this.socketToProfile.delete(client.id);
    }
  }

  @SubscribeMessage('call:invite')
  handleInvite(@MessageBody() data: { toProfileId: string; fromName: string }, @ConnectedSocket() client: Socket) {
    const fromProfileId = this.socketToProfile.get(client.id);
    if (!fromProfileId) return;
    const targetSocketId = this.profileToSocket.get(data.toProfileId);
    if (!targetSocketId) {
      client.emit('call:unavailable', { toProfileId: data.toProfileId });
      this.notifyMissedCall(data.toProfileId, fromProfileId, data.fromName).catch(() => {});
      return;
    }
    this.server.to(targetSocketId).emit('call:incoming', {
      fromProfileId,
      fromName: data.fromName,
    });
  }

  @SubscribeMessage('call:accept')
  handleAccept(@MessageBody() data: { toProfileId: string }, @ConnectedSocket() client: Socket) {
    this.relay('call:accepted', data.toProfileId, client);
  }

  @SubscribeMessage('call:reject')
  handleReject(@MessageBody() data: { toProfileId: string }, @ConnectedSocket() client: Socket) {
    this.relay('call:rejected', data.toProfileId, client);
  }

  @SubscribeMessage('call:offer')
  handleOffer(
    @MessageBody() data: { toProfileId: string; offer: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    this.relay('call:offer', data.toProfileId, client, { offer: data.offer });
  }

  @SubscribeMessage('call:answer')
  handleAnswer(
    @MessageBody() data: { toProfileId: string; answer: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    this.relay('call:answer', data.toProfileId, client, { answer: data.answer });
  }

  @SubscribeMessage('call:ice-candidate')
  handleIceCandidate(
    @MessageBody() data: { toProfileId: string; candidate: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    this.relay('call:ice-candidate', data.toProfileId, client, { candidate: data.candidate });
  }

  @SubscribeMessage('call:hangup')
  handleHangup(@MessageBody() data: { toProfileId: string }, @ConnectedSocket() client: Socket) {
    this.relay('call:hangup', data.toProfileId, client);
  }

  private relay(
    event: string,
    toProfileId: string,
    client: Socket,
    extra: Record<string, unknown> = {},
  ) {
    const targetSocketId = this.profileToSocket.get(toProfileId);
    if (!targetSocketId) return;
    const fromProfileId = this.socketToProfile.get(client.id);
    this.server.to(targetSocketId).emit(event, { fromProfileId, ...extra });
  }

  private async notifyMissedCall(toProfileId: string, fromProfileId: string, fromName: string) {
    if (!this.firebaseApp) return;
    const target = await this.prisma.user.findUnique({
      where: { id: toProfileId },
      select: { fcmToken: true },
    });
    if (!target?.fcmToken) return;

    try {
      await getMessaging(this.firebaseApp).send({
        token: target.fcmToken,
        notification: {
          title: `Missed call from ${fromName || 'Someone'}`,
          body: 'Open NIKAT to call them back.',
        },
        data: { type: 'missed_call', fromProfileId, fromName },
      });
    } catch (error) {
      this.logger.warn(`Missed-call push to ${toProfileId} failed (stale token?): ${error}`);
    }
  }
}
