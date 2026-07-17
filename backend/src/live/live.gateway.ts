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
import { Server, Socket } from 'socket.io';
import { corsOptions } from '../common/socket-cors';

interface BroadcastInfo {
  profileId: string;
  name: string;
  area: string;
  title: string;
  startedAt: number;
  viewerIds: Set<string>;
}

/**
 * Pure signaling relay for one-to-many live streaming - mirrors CallsGateway's
 * pattern but fans a single broadcaster's offer out to N viewers instead of
 * 1:1. No media ever passes through the server, only WebRTC offer/answer/ICE
 * payloads and the "who's live right now" registry. A caller's own identity
 * always comes from their JWT-verified connection (`socketToProfile`), never
 * from a client-claimed `profileId`/`fromProfileId` field - otherwise anyone
 * could start a broadcast as another user, or read another viewer's stream.
 */
@WebSocketGateway({ cors: corsOptions })
export class LiveGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly profileToSocket = new Map<string, string>();
  private readonly socketToProfile = new Map<string, string>();
  /** Keyed by broadcaster profileId. */
  private readonly broadcasts = new Map<string, BroadcastInfo>();
  /** Viewer profileId -> broadcaster profileId they're currently watching. */
  private readonly viewerToBroadcast = new Map<string, string>();

  constructor(private readonly jwt: JwtService) {}

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
    if (!profileId) return;
    this.profileToSocket.delete(profileId);
    this.socketToProfile.delete(client.id);

    if (this.broadcasts.has(profileId)) {
      this.stopBroadcast(profileId);
    }
    const watching = this.viewerToBroadcast.get(profileId);
    if (watching) {
      this.relay('live:viewer-left', watching, { viewerProfileId: profileId });
      this.broadcasts.get(watching)?.viewerIds.delete(profileId);
      this.viewerToBroadcast.delete(profileId);
    }
  }

  /** Lists currently-live broadcasters for a given area, newest first. */
  listActive(area: string) {
    return [...this.broadcasts.values()]
      .filter((b) => b.area.toLowerCase() === area.toLowerCase())
      .sort((a, b) => b.startedAt - a.startedAt)
      .map((b) => ({
        profileId: b.profileId,
        name: b.name,
        title: b.title,
        startedAt: b.startedAt,
        viewerCount: b.viewerIds.size,
      }));
  }

  @SubscribeMessage('live:start')
  handleStart(
    @MessageBody() data: { name: string; area: string; title: string },
    @ConnectedSocket() client: Socket,
  ) {
    const profileId = this.socketToProfile.get(client.id);
    if (!profileId) return;
    this.broadcasts.set(profileId, {
      profileId,
      name: data.name,
      area: data.area,
      title: data.title,
      startedAt: Date.now(),
      viewerIds: new Set(),
    });
  }

  @SubscribeMessage('live:stop')
  handleStop(@ConnectedSocket() client: Socket) {
    const profileId = this.socketToProfile.get(client.id);
    if (!profileId) return;
    this.stopBroadcast(profileId);
  }

  private stopBroadcast(broadcasterProfileId: string) {
    const info = this.broadcasts.get(broadcasterProfileId);
    if (!info) return;
    for (const viewerId of info.viewerIds) {
      this.relay('live:ended', viewerId, { broadcasterProfileId });
      this.viewerToBroadcast.delete(viewerId);
    }
    this.broadcasts.delete(broadcasterProfileId);
  }

  @SubscribeMessage('live:join')
  handleJoin(
    @MessageBody() data: { broadcasterProfileId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const viewerProfileId = this.socketToProfile.get(client.id);
    if (!viewerProfileId) return;
    const info = this.broadcasts.get(data.broadcasterProfileId);
    if (!info) {
      this.relay('live:ended', viewerProfileId, {
        broadcasterProfileId: data.broadcasterProfileId,
      });
      return;
    }
    info.viewerIds.add(viewerProfileId);
    this.viewerToBroadcast.set(viewerProfileId, data.broadcasterProfileId);
    this.relay('live:viewer-joined', data.broadcasterProfileId, { viewerProfileId });
  }

  @SubscribeMessage('live:leave')
  handleLeave(
    @MessageBody() data: { broadcasterProfileId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const viewerProfileId = this.socketToProfile.get(client.id);
    if (!viewerProfileId) return;
    this.broadcasts.get(data.broadcasterProfileId)?.viewerIds.delete(viewerProfileId);
    this.viewerToBroadcast.delete(viewerProfileId);
    this.relay('live:viewer-left', data.broadcasterProfileId, { viewerProfileId });
  }

  @SubscribeMessage('live:offer')
  handleOffer(
    @MessageBody() data: { toProfileId: string; offer: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    const fromProfileId = this.socketToProfile.get(client.id);
    if (!fromProfileId) return;
    this.relay('live:offer', data.toProfileId, { fromProfileId, offer: data.offer });
  }

  @SubscribeMessage('live:answer')
  handleAnswer(
    @MessageBody() data: { toProfileId: string; answer: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    const fromProfileId = this.socketToProfile.get(client.id);
    if (!fromProfileId) return;
    this.relay('live:answer', data.toProfileId, { fromProfileId, answer: data.answer });
  }

  @SubscribeMessage('live:ice-candidate')
  handleIceCandidate(
    @MessageBody() data: { toProfileId: string; candidate: unknown },
    @ConnectedSocket() client: Socket,
  ) {
    const fromProfileId = this.socketToProfile.get(client.id);
    if (!fromProfileId) return;
    this.relay('live:ice-candidate', data.toProfileId, { fromProfileId, candidate: data.candidate });
  }

  private relay(event: string, toProfileId: string, payload: Record<string, unknown>) {
    const targetSocketId = this.profileToSocket.get(toProfileId);
    if (!targetSocketId) return;
    this.server.to(targetSocketId).emit(event, payload);
  }
}
