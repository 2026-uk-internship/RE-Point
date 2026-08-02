// src/sockets/chatSocket.js
const jwt = require("jsonwebtoken");
const chatModel = require("../models/chatModel");

module.exports = (io) => {
  // 연결 시점에 토큰 검증
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;

    if (!token) return next(new Error("No token provided."));

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded; // { id, email }
      next();
    } catch (err) {
      next(new Error("Invalid or expired token."));
    }
  });

  io.on("connection", (socket) => {
    console.log(`User connected: ${socket.user.id}`);

    // 특정 채팅방(room)에 입장
    socket.on("join_room", async (roomId) => {
      socket.join(`room_${roomId}`);

      // 이전 대화 내역 불러와서 보내주기
      const history = await chatModel.getMessagesByRoom(roomId);
      socket.emit("chat_history", history);
    });

    // 메시지 전송
    socket.on("send_message", async ({ roomId, message }) => {
      const chatId = await chatModel.saveMessage({
        roomId,
        userId: socket.user.id,
        message,
      });

      const payload = {
        id: chatId,
        roomId,
        userId: socket.user.id,
        message,
        date: new Date(),
      };

      // 같은 방에 있는 사람들 전체에게 전송 (자신 포함)
      io.to(`room_${roomId}`).emit("receive_message", payload);
    });

    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.user.id}`);
    });
  });
};
