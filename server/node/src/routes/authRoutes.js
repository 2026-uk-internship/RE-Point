const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");

router.post("/signup", authController.signup); // POST /auth/signup
router.post("/login", authController.login); // POST /auth/login
router.delete("/:id", authController.deleteUser); // DELETE /auth/:id

module.exports = router;
