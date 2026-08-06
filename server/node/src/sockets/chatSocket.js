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

    // 이 소켓이 현재 "채팅 화면"으로 보고 있는 방 하나만 추적.
    // join_room이 호출될 때마다 이전 방은 반드시 leave 시켜서
    // 소켓이 여러 방에 동시에 물려있지 않도록 강제함.
    let activeRoomId = null;

    // 특정 채팅방(room)에 입장
    socket.on("join_room", async (roomId) => {
      // 이미 다른 방을 보고 있었다면 먼저 나가기.
      // 클라이언트가 leave_room을 못 보내는 경우(예: 강제 종료, 네트워크 끊김 후 재연결)에도
      // 서버가 스스로 정리하는 안전망 역할.
      if (activeRoomId && activeRoomId !== roomId) {
        socket.leave(`room_${activeRoomId}`);
      }

      socket.join(`room_${roomId}`);
      activeRoomId = roomId;

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

    // 채팅방 나가기 (화면 dispose, 뒤로가기, 메뉴의 leave 등에서 호출됨)
    // 클라이언트 ChatService.leaveChatRoom() / dispose()가 이걸 emit함.
    socket.on("leave_room", (roomId) => {
      socket.leave(`room_${roomId}`);
      if (activeRoomId === roomId) {
        activeRoomId = null;
      }
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

    // 연결 종료 시(로그아웃, 앱 종료, 네트워크 끊김 등).
    // socket.io는 disconnect 시 해당 소켓이 join했던 모든 room에서
    // 자동으로 빠지므로 room leave를 따로 호출할 필요는 없음.
    // (activeRoomId 변수 자체도 소켓과 함께 사라짐 — 클로저 안의 지역변수라 별도 정리 불필요)
    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.user.id}`);
    });
  });
};
