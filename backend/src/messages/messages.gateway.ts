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
 * Real-time delivery for private 1:1 chat messages, keyed by the
 * authenticated `userId` - deliberately mirrors calls.gateway.ts's own
 * register/relay pattern instead of sharing code with it, so chat changes
 * can't destabilize the working call feature. Message *persistence* happens
 * over REST (see messages.controller.ts); this only pushes already-saved
 * messages to the recipient if they're currently connected.
 */
@WebSocketGateway({ cors: { origin: true } })
export class MessagesGateway implements OnGatewayDisconnect {
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

  pushToUser(userId: string, message: unknown) {
    const socketId = this.userToSocket.get(userId);
    if (!socketId) return;
    this.server.to(socketId).emit('message:new', message);
  }
}
