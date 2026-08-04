// src/routes/userRoutes.js
const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const { verifyToken } = require("../middlewares/authMiddleware");
const upload = require("../config/upload");

router.put(
  "/me/profile-image",
  verifyToken,
  upload.single("image"), // 필드명 "image", 1장만
  userController.updateProfileImage,
);
router.get("/me", verifyToken, userController.getMyProfile); // GET /users/me
router.put("/me/location", verifyToken, userController.updateLocation); // PUT /users/me/location
router.get("/:id/profile", userController.getPublicProfile); // GET /users/:id/profile

module.exports = router;
