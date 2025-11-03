import {
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UsePipes, ValidationPipe } from '@nestjs/common';
import { ChatService } from '../chat.service';
import { JoinRoomDto, SendMessageDto, LeaveRoomDto } from '../dto/chat.dto';
import { Message } from '../interfaces/message.interface';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/chat',
})
@UsePipes(new ValidationPipe())
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;
  private logger: Logger = new Logger('ChatGateway');

  constructor(private chatService: ChatService) {}

  afterInit() {
    this.logger.log('WebSocket server initialized');
  }

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
    client.emit('connected', { socketId: client.id });
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    this.chatService.removeUser(client.id);
  }

  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @MessageBody() data: JoinRoomDto,
    @ConnectedSocket() client: Socket,
  ) {
    const { room, username } = data;

    await client.join(room);
    this.chatService.addUser(client.id, username, room);

    // Send existing messages to the new user
    const existingMessages = this.chatService.getMessagesForRoom(room);
    for (const msg of existingMessages) {
      client.emit('message', msg);
    }

    const message: Message = {
      id: Date.now().toString(),
      username: 'System',
      text: `${username} has joined the room`,
      room,
      timestamp: new Date(),
    };

    // Add the join message to history
    this.chatService.addMessage(message);
    this.server.to(room).emit('message', message);

    const usersInRoom = this.chatService.getUsersInRoom(room);
    this.server.to(room).emit('roomUsers', usersInRoom);

    this.logger.log(`User ${username} successfully joined room ${room}`);
    return { success: true, room };
  }

  @SubscribeMessage('sendMessage')
  handleMessage(
    @MessageBody() data: SendMessageDto,
    @ConnectedSocket() client: Socket,
  ) {
    const { message: text, room } = data;
    const user = this.chatService.getUser(client.id);

    if (!user) {
      return { event: 'error', data: 'User not found' };
    }

    const message: Message = {
      id: Date.now().toString(),
      username: user.username,
      text,
      room,
      timestamp: new Date(),
    };

    this.chatService.addMessage(message);
    this.server.to(room).emit('message', message);

    return { event: 'messageSent', data: message };
  }

  @SubscribeMessage('leaveRoom')
  async handleLeaveRoom(
    @MessageBody() data: LeaveRoomDto,
    @ConnectedSocket() client: Socket,
  ) {
    const { room } = data;
    const user = this.chatService.getUser(client.id);

    if (!user) {
      return { event: 'error', data: 'User not found' };
    }

    await client.leave(room);
    this.chatService.removeUserFromRoom(client.id, room);

    const message: Message = {
      id: Date.now().toString(),
      username: 'System',
      text: `${user.username} has left the room`,
      room,
      timestamp: new Date(),
    };

    // Add the leave message to history
    this.chatService.addMessage(message);
    this.server.to(room).emit('message', message);

    const usersInRoom = this.chatService.getUsersInRoom(room);
    this.server.to(room).emit('roomUsers', usersInRoom);

    return { event: 'leftRoom', data: { room } };
  }

  @SubscribeMessage('typing')
  handleTyping(
    @MessageBody() data: { room: string; isTyping: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    const user = this.chatService.getUser(client.id);
    if (user) {
      client.to(data.room).emit('userTyping', {
        username: user.username,
        isTyping: data.isTyping,
      });
    }
  }
}
