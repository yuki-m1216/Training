"use client";

import { use, useEffect, useRef, useState } from "react";
import { io, Socket } from "socket.io-client";
import type {
  ServerToClientEvents,
  ClientToServerEvents,
} from "@/types/socket";

export const useSocket = () => {
  const [socket, setSocket] = useState<Socket<
    ServerToClientEvents,
    ClientToServerEvents
  > | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const socketUrl =
      process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3000";

    const socketInstance: Socket<ServerToClientEvents, ClientToServerEvents> =
      io(`${socketUrl}/chat`, {
        transports: ["websocket", "polling"],
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
      });

    socketInstance.on("connect", () => {
      console.log("Connected to socket server", socketInstance.id);
      setIsConnected(true);
    });

    socketInstance.on("disconnect", () => {
      console.log("Disconnected from socket server");
      setIsConnected(false);
    });

    socketInstance.on("connect_error", (err) => {
      console.error("Connection error:", err.message);
      setIsConnected(false);
    });
    
    // Debug info
    console.log("Socket.io connecting to:", `${socketUrl}/chat`);
    console.log("Socket instance created:", socketInstance);

    setSocket(socketInstance);

    return () => {
      socketInstance.disconnect();
    };
  }, []);

  return { socket, isConnected };
};
