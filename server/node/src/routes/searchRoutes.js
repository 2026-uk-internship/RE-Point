// src/routes/searchRoutes.js
const express = require("express");
const router = express.Router();
const searchController = require("../controllers/searchController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/", verifyToken, searchController.searchProducts); // GET /search?keyword=
router.get("/popular", searchController.getPopularSearches); // GET /search/popular
router.get("/recent", verifyToken, searchController.getRecentSearches); // GET /search/recent
router.delete(
  "/recent/:searchId",
  verifyToken,
  searchController.deleteRecentSearch,
); // DELETE /search/recent/:searchId

module.exports = router;
