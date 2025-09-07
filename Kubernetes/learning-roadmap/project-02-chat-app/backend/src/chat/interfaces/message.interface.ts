export interface Message {
  id: string;
  username: string;
  text: string;
  room: string;
  timestamp: Date;
}

export interface UserInfo {
  socketId: string;
  username: string;
  rooms: string[];
}

export interface RoomInfo {
  name: string;
  users: string[];
  createdAt: Date;
}
