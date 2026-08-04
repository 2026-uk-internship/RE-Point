const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/me", verifyToken, userController.getMyProfile); // GET /users/me
router.put("/me/location", verifyToken, userController.updateLocation); // PUT /users/me/location

module.exports = router;
