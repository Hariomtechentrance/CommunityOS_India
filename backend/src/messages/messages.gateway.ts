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
 * Real-time delivery for private 1:1 chat messages, keyed by the
 * authenticated `userId` - deliberately mirrors calls.gateway.ts's own
 * register/relay pattern instead of sharing code with it, so chat changes
 * can't destabilize the working call feature. Message *persistence* happens
 * over REST (see messages.controller.ts); this only pushes already-saved
 * messages to the recipient if they're currently connected. Identity comes
 * from a JWT verified at connection time - otherwise anyone could register
 * as another user's id and read their private messages.
 */
@WebSocketGateway({ cors: corsOptions })
export class MessagesGateway implements OnGatewayConnection, OnGatewayDisconnect {
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

  pushToUser(userId: string, message: unknown) {
    const socketId = this.userToSocket.get(userId);
    if (!socketId) return;
    this.server.to(socketId).emit('message:new', message);
  }
}
