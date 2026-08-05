/**
 * 상품 실시간 시청자 관리 소켓 이벤트를 등록합니다.
 * @param {import('socket.io').Server} io - Socket.IO 서버 인스턴스
 */
module.exports = function setupProductSockets(io) {
  // 방 단위 시청자 정보 업데이트 및 브로드캐스트 함수
  async function updateRoomViewers(roomName) {
    try {
      const sockets = await io.in(roomName).fetchSockets();

      // 방에 접속 중인 유저 정보 추출 (익명 사용자 기본값 처리)
      const viewers = sockets.map((s) => s.userData).filter(Boolean);

      // 해당 방의 모든 클라이언트에게 갱신된 시청자 정보 전송
      io.to(roomName).emit("product_viewers_updated", {
        count: viewers.length,
        viewers: viewers,
      });
    } catch (error) {
      console.error(`[Socket Error] ${roomName} 시청자 집계 실패:`, error);
    }
  }

  io.on("connection", (socket) => {
    // 1. 상품 상세 페이지 진입
    socket.on("join_product", async (data) => {
      const { productId, userId, userName, userImg } = data || {}; // userImg 추가
      if (!productId) return;

      const roomName = `product_${productId}`;

      if (!socket.rooms.has(roomName)) {
        await socket.join(roomName);
      }

      socket.currentProductRoom = roomName;
      socket.userData = {
        userId: userId || `guest_${socket.id.substring(0, 5)}`,
        userName: userName || "익명 사용자",
        userImg: userImg || null, // 프로필 이미지 URL 저장 (없으면 null)
        joinedAt: new Date(),
      };

      await updateRoomViewers(roomName);
    });

    // 2. 상품 상세 페이지 이탈 (다른 화면으로 이동 등)
    socket.on("leave_product", async (data) => {
      const { productId } = data || {};
      const roomName = productId
        ? `product_${productId}`
        : socket.currentProductRoom;

      if (roomName && socket.rooms.has(roomName)) {
        await socket.leave(roomName);
        delete socket.currentProductRoom;
        delete socket.userData;

        await updateRoomViewers(roomName);
      }
    });

    // 3. 앱 종료, 뒤로 가기, 네트워크 끊김 등으로 연결이 끊길 때 자동 처리
    socket.on("disconnecting", async () => {
      // 연결이 끊어지기 전 속해있던 모든 상품 방의 시청자 수 업데이트
      for (const roomName of socket.rooms) {
        if (roomName.startsWith("product_")) {
          // 약간의 지연을 주어 소켓 이탈 처리가 완전히 완료된 후 집계
          setImmediate(() => updateRoomViewers(roomName));
        }
      }
    });
  });
};
