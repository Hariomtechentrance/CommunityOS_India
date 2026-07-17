import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { corsOptions } from '../common/socket-cors';

/**
 * Real-time delivery for emergency SOS alerts, keyed by the authenticated
 * `userId` - deliberately mirrors calls.gateway.ts / messages.gateway.ts's
 * own independent register/relay pattern rather than sharing code with
 * them, so this can't destabilize the working call/chat features. Identity
 * comes from a JWT verified at connection time, not a client-claimed id -
 * otherwise anyone could register as another user and receive their SOS
 * alerts (or spoof the "who has the app open" presence signal below).
 */
@WebSocketGateway({ cors: corsOptions })
export class AlertsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly userToSocket = new Map<string, string>();
  private readonly socketToUser = new Map<string, string>();

  constructor(private readonly jwt: JwtService) {}

  handleConnection(client: Socket) {
    const token = client.handshake.auth?.token as string | undefined;
    if (!token) {
      client.disconnect(true);
      return;
    }
    try {
      const payload = this.jwt.verify<{ sub: string }>(token);
      this.userToSocket.set(payload.sub, client.id);
      this.socketToUser.set(client.id, payload.sub);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = this.socketToUser.get(client.id);
    if (userId) {
      this.userToSocket.delete(userId);
      this.socketToUser.delete(client.id);
    }
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
