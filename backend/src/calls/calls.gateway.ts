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
import { randomUUID } from 'crypto';
import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { Server, Socket } from 'socket.io';
import { FIREBASE_ADMIN } from '../auth/firebase-admin.provider';
import { PrismaService } from '../prisma/prisma.service';
import { corsOptions } from '../common/socket-cors';

interface PendingInvite {
  fromProfileId: string;
  fromName: string;
  callId: string;
  timer: NodeJS.Timeout;
}

/**
 * Pure signaling relay for in-app calling - no media ever passes through the
 * server, only WebRTC offer/answer/ICE payloads, keyed by the caller's/
 * callee's authenticated `userId`. That identity comes from a JWT verified
 * at connection time (`handshake.auth.token`), not from anything the client
 * claims in a message payload - otherwise any client could register as, and
 * receive calls for, an arbitrary other user.
 *
 * If the target isn't connected via socket right now, the call doesn't fail
 * instantly - it stays "ringing" for RING_TIMEOUT_MS while a high-priority
 * FCM data push tries to wake their device (native Android answers this via
 * a self-managed ConnectionService, so it rings and shows a real incoming-
 * call screen even from a fully closed app). If they connect and accept
 * within that window, the call proceeds normally; only past the timeout
 * does the caller get a definitive "no answer".
 */
@WebSocketGateway({ cors: corsOptions })
export class CallsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(CallsGateway.name);
  private static readonly RING_TIMEOUT_MS = 45_000;

  @WebSocketServer()
  server: Server;

  private readonly profileToSocket = new Map<string, string>();
  private readonly socketToProfile = new Map<string, string>();
  /** Keyed by the callee's profileId - only one outstanding invite per
   * callee at a time, matching the client's own "one call at a time" rule. */
  private readonly pendingInvites = new Map<string, PendingInvite>();

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
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('call:incoming', {
        fromProfileId,
        fromName: data.fromName,
      });
      return;
    }

    // Not connected right now - hold the invite open and try to wake their
    // device with a high-priority push instead of failing instantly.
    this.clearPendingInvite(data.toProfileId);
    const callId = randomUUID();
    const timer = setTimeout(() => {
      this.pendingInvites.delete(data.toProfileId);
      client.emit('call:no-answer', { toProfileId: data.toProfileId });
      this.notifyMissedCall(data.toProfileId, fromProfileId, data.fromName).catch(() => {});
    }, CallsGateway.RING_TIMEOUT_MS);
    this.pendingInvites.set(data.toProfileId, { fromProfileId, fromName: data.fromName, callId, timer });

    client.emit('call:ringing', { toProfileId: data.toProfileId });
    this.notifyIncomingCallPush(data.toProfileId, fromProfileId, data.fromName, callId).catch(() => {});
  }

  /**
   * `toProfileId` is set when the app already knew who was calling (the
   * normal in-app path, via the `call:incoming` socket event). `callId` is
   * set instead when this comes from tapping "Answer" on the native
   * ConnectionService call screen woken by a push - that flow runs in a
   * separate isolate from the rest of the app, with no access to who's
   * actually calling, so the client only has the callId from the push
   * payload. Either way, resolving through `pendingInvites` finds the real
   * caller and tells the callee who it is via `call:invite-info`, since their
   * own WebRTC signaling needs that id and the client can't otherwise know it.
   */
  @SubscribeMessage('call:accept')
  handleAccept(
    @MessageBody() data: { toProfileId?: string; callId?: string },
    @ConnectedSocket() client: Socket,
  ) {
    let targetProfileId = data.toProfileId;
    const myProfileId = this.socketToProfile.get(client.id);
    if (myProfileId) {
      const pending = this.pendingInvites.get(myProfileId);
      if (pending && (!data.callId || pending.callId === data.callId)) {
        targetProfileId = pending.fromProfileId;
        this.clearPendingInvite(myProfileId);
        client.emit('call:invite-info', {
          fromProfileId: pending.fromProfileId,
          fromName: pending.fromName,
        });
      }
    }
    if (!targetProfileId) return;
    this.relay('call:accepted', targetProfileId, client);
  }

  @SubscribeMessage('call:reject')
  handleReject(
    @MessageBody() data: { toProfileId?: string; callId?: string },
    @ConnectedSocket() client: Socket,
  ) {
    let targetProfileId = data.toProfileId;
    const myProfileId = this.socketToProfile.get(client.id);
    if (myProfileId) {
      const pending = this.pendingInvites.get(myProfileId);
      if (pending && (!data.callId || pending.callId === data.callId)) {
        targetProfileId = pending.fromProfileId;
        this.clearPendingInvite(myProfileId);
      }
    }
    if (!targetProfileId) return;
    this.relay('call:rejected', targetProfileId, client);
  }

  private clearPendingInvite(toProfileId: string) {
    const pending = this.pendingInvites.get(toProfileId);
    if (!pending) return;
    clearTimeout(pending.timer);
    this.pendingInvites.delete(toProfileId);
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
    // Caller gave up before the callee's device answered - if a wake-up
    // push already got their phone ringing (native ConnectionService), it
    // needs to be told to stop, or it'd ring until the 45s timeout regardless.
    const pending = this.pendingInvites.get(data.toProfileId);
    if (pending) {
      this.clearPendingInvite(data.toProfileId);
      this.notifyCallCancelled(data.toProfileId, pending.callId).catch(() => {});
    }
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
    const token = await this.getFcmToken(toProfileId);
    if (!token || !this.firebaseApp) return;

    try {
      await getMessaging(this.firebaseApp).send({
        token,
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

  /** Data-only + high priority, deliberately no `notification` field - this
   * must invoke the app's own message handler (native ConnectionService) even
   * from a fully closed app, not just surface a passive system notification
   * that the OS would otherwise show without running any of our code. */
  private async notifyIncomingCallPush(
    toProfileId: string,
    fromProfileId: string,
    fromName: string,
    callId: string,
  ) {
    const token = await this.getFcmToken(toProfileId);
    if (!token || !this.firebaseApp) return;

    try {
      await getMessaging(this.firebaseApp).send({
        token,
        android: { priority: 'high' },
        data: { type: 'incoming_call', callId, fromProfileId, fromName },
      });
    } catch (error) {
      this.logger.warn(`Incoming-call push to ${toProfileId} failed (stale token?): ${error}`);
    }
  }

  /** Tells a device that already started ringing (via the push above) to
   * stop - the caller hung up before this call was answered. */
  private async notifyCallCancelled(toProfileId: string, callId: string) {
    const token = await this.getFcmToken(toProfileId);
    if (!token || !this.firebaseApp) return;

    try {
      await getMessaging(this.firebaseApp).send({
        token,
        android: { priority: 'high' },
        data: { type: 'call_cancelled', callId },
      });
    } catch (error) {
      this.logger.warn(`Call-cancelled push to ${toProfileId} failed (stale token?): ${error}`);
    }
  }

  private async getFcmToken(userId: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true } });
    return user?.fcmToken ?? null;
  }
}
