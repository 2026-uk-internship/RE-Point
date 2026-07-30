const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/signup", authController.signup); // POST /auth/signup
router.post("/login", authController.login); // POST /auth/login
router.delete("/:id", verifyToken, authController.deleteUser); // DELETE /auth/:id

module.exports = router;
