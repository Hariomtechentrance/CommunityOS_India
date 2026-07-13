import {
  ConnectedSocket,
  MessageBody,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

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
 * payloads and the "who's live right now" registry.
 */
@WebSocketGateway({ cors: { origin: true } })
export class LiveGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly profileToSocket = new Map<string, string>();
  private readonly socketToProfile = new Map<string, string>();
  /** Keyed by broadcaster profileId. */
  private readonly broadcasts = new Map<string, BroadcastInfo>();
  /** Viewer profileId -> broadcaster profileId they're currently watching. */
  private readonly viewerToBroadcast = new Map<string, string>();

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

  @SubscribeMessage('register')
  handleRegister(@MessageBody() data: { profileId: string }, @ConnectedSocket() client: Socket) {
    this.profileToSocket.set(data.profileId, client.id);
    this.socketToProfile.set(client.id, data.profileId);
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
    @MessageBody() data: { profileId: string; name: string; area: string; title: string },
  ) {
    this.broadcasts.set(data.profileId, {
      profileId: data.profileId,
      name: data.name,
      area: data.area,
      title: data.title,
      startedAt: Date.now(),
      viewerIds: new Set(),
    });
  }

  @SubscribeMessage('live:stop')
  handleStop(@MessageBody() data: { profileId: string }) {
    this.stopBroadcast(data.profileId);
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
    @MessageBody() data: { broadcasterProfileId: string; viewerProfileId: string },
  ) {
    const info = this.broadcasts.get(data.broadcasterProfileId);
    if (!info) {
      this.relay('live:ended', data.viewerProfileId, {
        broadcasterProfileId: data.broadcasterProfileId,
      });
      return;
    }
    info.viewerIds.add(data.viewerProfileId);
    this.viewerToBroadcast.set(data.viewerProfileId, data.broadcasterProfileId);
    this.relay('live:viewer-joined', data.broadcasterProfileId, {
      viewerProfileId: data.viewerProfileId,
    });
  }

  @SubscribeMessage('live:leave')
  handleLeave(
    @MessageBody() data: { broadcasterProfileId: string; viewerProfileId: string },
  ) {
    this.broadcasts.get(data.broadcasterProfileId)?.viewerIds.delete(data.viewerProfileId);
    this.viewerToBroadcast.delete(data.viewerProfileId);
    this.relay('live:viewer-left', data.broadcasterProfileId, {
      viewerProfileId: data.viewerProfileId,
    });
  }

  @SubscribeMessage('live:offer')
  handleOffer(@MessageBody() data: { toProfileId: string; fromProfileId: string; offer: unknown }) {
    this.relay('live:offer', data.toProfileId, { fromProfileId: data.fromProfileId, offer: data.offer });
  }

  @SubscribeMessage('live:answer')
  handleAnswer(
    @MessageBody() data: { toProfileId: string; fromProfileId: string; answer: unknown },
  ) {
    this.relay('live:answer', data.toProfileId, {
      fromProfileId: data.fromProfileId,
      answer: data.answer,
    });
  }

  @SubscribeMessage('live:ice-candidate')
  handleIceCandidate(
    @MessageBody() data: { toProfileId: string; fromProfileId: string; candidate: unknown },
  ) {
    this.relay('live:ice-candidate', data.toProfileId, {
      fromProfileId: data.fromProfileId,
      candidate: data.candidate,
    });
  }

  private relay(event: string, toProfileId: string, payload: Record<string, unknown>) {
    const targetSocketId = this.profileToSocket.get(toProfileId);
    if (!targetSocketId) return;
    this.server.to(targetSocketId).emit(event, payload);
  }
}
