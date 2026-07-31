const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/signup", authController.signup); // POST /auth/signup
router.post("/login", authController.login); // POST /auth/login
router.delete("/:id", verifyToken, authController.deleteUser); // DELETE /auth/:id

router.post("/email/send", authController.sendVerificationEmail); // POST /auth/email/send
router.post("/email/verify", authController.verifyEmailCode); // POST /auth/email/verify

module.exports = router;
