const express = require("express");
const router = express.Router();
const roomController = require("../controllers/roomController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/", verifyToken, roomController.getRoomList); // GET /rooms
// GET /rooms                  // 전체 목록
// GET /rooms?keyword=철수      // "철수"가 이름에 포함된 상대방과의 채팅방만
router.post("/", verifyToken, roomController.enterRoom); // POST /rooms

module.exports = router;
