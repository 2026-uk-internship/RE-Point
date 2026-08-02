// src/routes/productRoutes.js
const express = require("express");
const router = express.Router();
const productController = require("../controllers/productController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/", verifyToken, productController.createProduct); // POST /products
router.get("/main", productController.getMainList); // GET /products/main
router.get("/auctions", productController.getAuctionList); // GET /products/auctions
router.get("/:id", productController.getProductDetail); // GET /products/:id

// TODO: 경매 세부 페이지 디자인 확정 후 라우트 추가
// router.get("/auctions/:id", productController.getAuctionDetail);

module.exports = router;
