const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/me", verifyToken, userController.getMyProfile); // GET /users/me

module.exports = router;
