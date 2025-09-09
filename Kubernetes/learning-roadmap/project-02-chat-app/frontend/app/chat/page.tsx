"use client";
import React, { useEffect, useState, useRef } from "react";
import { useSocket } from "@/hooks/useSocket";
import type { Message } from "@/types/socket";

export default function ChatPage() {
  const { socket, isConnected } = useSocket();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputMessage, setInputMessage] = useState("");
  const [username, setUsername] = useState("");
  const [room, setRoom] = useState("");
  const [isJoined, setIsJoined] = useState(false);
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!socket) return;

    socket.on("message", (message: Message) => {
      setMessages((prev) => [...prev, message]);
    });

    socket.on("userJoined", ({ userName, room }) => {
      console.log(`${userName} joined room ${room}`);
    });

    socket.on("userLeft", ({ userName, room }) => {
      console.log(`${userName} left room ${room}`);
    });

    socket.on("typing", ({ userId, userName, isTyping }) => {
      setTypingUsers((prev) => {
        const newSet = new Set(prev);
        if (isTyping) {
          newSet.add(userId);
        } else {
          newSet.delete(userId);
        }
        return newSet;
      });
    });

    return () => {
      socket.off("message");
      socket.off("userJoined");
      socket.off("userLeft");
      socket.off("typing");
    };
  }, [socket]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleJoinRoom = () => {
    if (!socket || !username || !room) return;
    console.log("Joining room:", { username, room });
    socket.emit("joinRoom", { username, room }, (response) => {
      console.log("Join room response:", response);
      if (response?.success) {
        setIsJoined(true);
        setMessages([]);
      } else {
        console.error("Failed to join room:", response);
      }
    });
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!socket || !inputMessage.trim() || !isJoined) return;

    socket.emit("sendMessage", { room, message: inputMessage });
    setInputMessage("");
  };

  const handleTyping = () => {
    if (!socket || !isJoined) return;

    socket.emit("typing", { room, isTyping: true });

    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }

    typingTimeoutRef.current = setTimeout(() => {
      socket.emit("typing", { room, isTyping: false });
    }, 1000);
  };

  const handleLeaveRoom = () => {
    if (!socket || !isJoined) return;
    socket.emit("leaveRoom", { room });
    setIsJoined(false);
    setMessages([]);
  };

  if (!isJoined) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-md w-96">
          <h1 className="text-2xl font-bold mb-6 text-center">
            チャットに参加
          </h1>
          <div className="space-y-4">
            <input
              type="text"
              placeholder="ユーザー名"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2
  focus:ring-blue-500"
            />
            <input
              type="text"
              placeholder="ルーム名"
              value={room}
              onChange={(e) => setRoom(e.target.value)}
              className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2
  focus:ring-blue-500"
            />
            <button
              onClick={handleJoinRoom}
              disabled={!isConnected || !username || !room}
              className="w-full bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 
  disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              {isConnected ? "参加" : "接続中..."}
            </button>
          </div>
        </div>
      </div>
    );
  }
  return (
    <div className="min-h-screen flex flex-col bg-gray-100">
      <header className="bg-white shadow-sm px-6 py-4">
        <div className="flex justify-between items-center">
          <h1 className="text-xl font-semibold">ルーム: {room}</h1>
          <button
            onClick={handleLeaveRoom}
            className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
          >
            退出
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-hidden flex flex-col max-w-4xl mx-auto w-full">
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${
                message.username === username ? "justify-end" : "justify-start"
              }`}
            >
              <div
                className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                  message.username === username
                    ? "bg-blue-500 text-white"
                    : "bg-white text-gray-800"
                }`}
              >
                <p className="text-xs font-semibold mb-1">{message.username}</p>
                <p>{message.text}</p>
                <p className="text-xs mt-1 opacity-70">
                  {new Date(message.timestamp).toLocaleTimeString()}
                </p>
              </div>
            </div>
          ))}
          {typingUsers.size > 0 && (
            <div className="text-sm text-gray-500 italic">
              {Array.from(typingUsers).join(", ")} が入力中...
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <form onSubmit={handleSendMessage} className="p-4 bg-white border-t">
          <div className="flex space-x-2">
            <input
              type="text"
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={handleTyping}
              placeholder="メッセージを入力..."
              className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2
  focus:ring-blue-500"
            />
            <button
              type="submit"
              disabled={!inputMessage.trim()}
              className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:bg-gray-300
   disabled:cursor-not-allowed"
            >
              送信
            </button>
          </div>
        </form>
      </main>
    </div>
  );
}
