const express = require("express");
const router = express.Router();

const reportController = require("../controllers/reportController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/", verifyToken, reportController.createReport);

module.exports = router;
