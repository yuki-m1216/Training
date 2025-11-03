import { Injectable } from '@nestjs/common';
import { Message, UserInfo } from './interfaces/message.interface';

@Injectable()
export class ChatService {
  private users = new Map<string, UserInfo>();
  private messages: Message[] = [];
  private rooms = new Map<string, Set<string>>();

  addUser(socketId: string, username: string, room: string) {
    const user = this.users.get(socketId) || {
      socketId,
      username,
      rooms: [],
    };

    if (!user.rooms.includes(room)) {
      user.rooms.push(room);
    }

    this.users.set(socketId, user);

    if (!this.rooms.has(room)) {
      this.rooms.set(room, new Set());
    }
    this.rooms.get(room)?.add(socketId);

    return user;
  }

  removeUser(socketId: string) {
    const user = this.users.get(socketId);
    if (user) {
      user.rooms.forEach((room) => {
        this.rooms.get(room)?.delete(socketId);
      });
      this.users.delete(socketId);
    }
  }

  removeUserFromRoom(socketId: string, room: string) {
    const user = this.users.get(socketId);
    if (user) {
      user.rooms = user.rooms.filter((r) => r !== room);
      this.rooms.get(room)?.delete(socketId);
    }
  }

  getUser(socketId: string): UserInfo | undefined {
    return this.users.get(socketId);
  }

  getUsersInRoom(room: string): string[] {
    const roomUsers = this.rooms.get(room);
    if (!roomUsers) return [];

    return Array.from(roomUsers)
      .map((socketId) => this.users.get(socketId))
      .filter((user) => user !== undefined)
      .map((user) => user.username);
  }

  addMessage(message: Message) {
    this.messages.push(message);
    this.messages = this.messages.slice(-100); // Keep only the last 100 messages
  }

  getMessagesForRoom(room: string): Message[] {
    return this.messages.filter((msg) => msg.room === room);
  }
}
