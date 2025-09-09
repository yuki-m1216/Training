export interface Message {
  id: string;
  text: string;
  username: string;
  room: string;
  timestamp: Date;
}

export interface ServerToClientEvents {
    message: (data: Message) => void;
    userJoined: (data: { userId: string; userName: string; room: string }) => void;
    userLeft: (data: { userId: string; userName: string; room: string }) => void;
    typing: (data: { userId: string; userName: string; isTyping: boolean}) => void;
    error: (data: { message: string }) => void;
}

export interface ClientToServerEvents {
    joinRoom: (data: { username: string; room: string}, callback?: (response: {success: boolean; room: string }) => void) => void;
    sendMessage: (data: { room: string; message: string }) => void;
    leaveRoom: (data: { room: string }) => void;
    typing: (data: { room: string; isTyping: boolean }) => void;
}
