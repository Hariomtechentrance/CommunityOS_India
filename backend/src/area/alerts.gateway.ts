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
 * Real-time delivery for emergency SOS alerts, keyed by the authenticated
 * `userId` - deliberately mirrors calls.gateway.ts / messages.gateway.ts's
 * own independent register/relay pattern rather than sharing code with
 * them, so this can't destabilize the working call/chat features.
 */
@WebSocketGateway({ cors: { origin: true } })
export class AlertsGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly userToSocket = new Map<string, string>();
  private readonly socketToUser = new Map<string, string>();

  handleDisconnect(client: Socket) {
    const userId = this.socketToUser.get(client.id);
    if (userId) {
      this.userToSocket.delete(userId);
      this.socketToUser.delete(client.id);
    }
  }

  @SubscribeMessage('register')
  handleRegister(@MessageBody() data: { userId: string }, @ConnectedSocket() client: Socket) {
    this.userToSocket.set(data.userId, client.id);
    this.socketToUser.set(client.id, data.userId);
  }

  /**
   * Every logged-in user connects here the moment the app opens (it's the
   * SOS alert channel, mounted app-wide) - so this doubles as a ready-made
   * "who currently has the app open" presence signal, with no separate
   * heartbeat/last-seen tracking needed.
   */
  getConnectedUserIds(): string[] {
    return [...this.userToSocket.keys()];
  }

  pushToUsers(userIds: string[], payload: unknown) {
    for (const userId of userIds) {
      const socketId = this.userToSocket.get(userId);
      if (!socketId) continue;
      this.server.to(socketId).emit('alert:incoming', payload);
    }
  }
}
