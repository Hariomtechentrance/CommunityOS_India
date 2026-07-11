import {
  ConnectedSocket,
  MessageBody,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

/**
 * Pure signaling relay for in-app calling - no media ever passes through the
 * server, only WebRTC offer/answer/ICE payloads, keyed by the caller's/
 * callee's authenticated `userId` (the client reads this from its own
 * session). If the target user isn't currently connected, the caller gets
 * `call:unavailable`.
 */
@WebSocketGateway({ cors: { origin: true } })
export class CallsGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly profileToSocket = new Map<string, string>();
  private readonly socketToProfile = new Map<string, string>();

  handleDisconnect(client: Socket) {
    const profileId = this.socketToProfile.get(client.id);
    if (profileId) {
      this.profileToSocket.delete(profileId);
      this.socketToProfile.delete(client.id);
    }
  }

  @SubscribeMessage('register')
  handleRegister(
    @MessageBody() data: { profileId: string },
    @ConnectedSocket() client: Socket,
  ) {
    this.profileToSocket.set(data.profileId, client.id);
    this.socketToProfile.set(client.id, data.profileId);
  }

  @SubscribeMessage('call:invite')
  handleInvite(
    @MessageBody() data: { toProfileId: string; fromProfileId: string; fromName: string },
    @ConnectedSocket() client: Socket,
  ) {
    const targetSocketId = this.profileToSocket.get(data.toProfileId);
    if (!targetSocketId) {
      client.emit('call:unavailable', { toProfileId: data.toProfileId });
      return;
    }
    this.server.to(targetSocketId).emit('call:incoming', {
      fromProfileId: data.fromProfileId,
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
}
