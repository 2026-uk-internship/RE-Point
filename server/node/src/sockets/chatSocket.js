// src/sockets/chatSocket.js
const jwt = require("jsonwebtoken");
const chatModel = require("../models/chatModel");
const roomModel = require("../models/roomModel");
const { getTemperatureLevel } = require("../utils/temperature");
const { formatTimeAMPM } = require("../utils/formatTime");

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

      const roomInfo = await roomModel.getRoomInfo(roomId, socket.user.id);
      socket.emit("room_info", {
        counterpartName: roomInfo.counterpartName,
        counterpartTemperature: roomInfo.counterpartTemperature,
        counterpartTemperatureLevel: getTemperatureLevel(
          roomInfo.counterpartTemperature,
        ),
        productImg: roomInfo.productImg,
      });

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
      const now = new Date();

      const payload = {
        id: chatId,
        roomId,
        userId: socket.user.id,
        message,
        date: now,
        timeDisplay: formatTimeAMPM(now),
      };

      // 같은 방에 있는 사람들 전체에게 전송 (자신 포함)
      io.to(`room_${roomId}`).emit("receive_message", payload);
    });

    // 작성 중 표시
    socket.on("typing", ({ roomId }) => {
      socket
        .to(`room_${roomId}`)
        .emit("user_typing", { userId: socket.user.id });
    });

    socket.on("stop_typing", ({ roomId }) => {
      socket
        .to(`room_${roomId}`)
        .emit("user_stop_typing", { userId: socket.user.id });
    });

    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.user.id}`);
    });
  });
};
