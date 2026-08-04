// src/routes/productRoutes.js
const express = require("express");
const router = express.Router();
const productController = require("../controllers/productController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/", verifyToken, productController.createProduct);
router.get("/general", productController.getGeneralList);
router.get("/point", productController.getPointList);
router.get("/auctions", productController.getAuctionList);
router.get("/:id/related-category", productController.getRelatedByCategory); // ← :id보다 위
router.get("/:id/related-seller", productController.getRelatedBySeller); // ← :id보다 위
router.get("/:id", productController.getProductDetail);

// TODO: 경매 세부 페이지 디자인 확정 후 라우트 추가
// router.get("/auctions/:id", productController.getAuctionDetail);

module.exports = router;
