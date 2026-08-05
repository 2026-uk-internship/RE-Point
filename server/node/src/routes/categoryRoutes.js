// src/routes/categoryRoutes.js
const express = require("express");
const router = express.Router();
const categoryController = require("../controllers/categoryController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/", categoryController.getCategories); // GET /api/categories
router.get("/users/:id", categoryController.getUserCategories); // GET /api/categories/users/n
router.put("/users/:id", verifyToken, categoryController.setUserCategories); // PUT /api/categories/users/n
router.get("/groups", categoryController.getGroups); // GET /category/groups
router.get("/groups/:id/categories", categoryController.getGroupCategories); // GET /category/groups/:id/categories

module.exports = router;
