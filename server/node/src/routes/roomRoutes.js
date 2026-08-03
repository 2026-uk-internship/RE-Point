const express = require("express");
const router = express.Router();
const roomController = require("../controllers/roomController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/", verifyToken, roomController.getRoomList); // GET /rooms
router.post("/", verifyToken, roomController.enterRoom); // POST /rooms

module.exports = router;
