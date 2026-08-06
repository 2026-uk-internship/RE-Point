// src/routes/productRoutes.js
const express = require("express");
const router = express.Router();
const productController = require("../controllers/productController");
const bidController = require("../controllers/bidController");
const { verifyToken } = require("../middlewares/authMiddleware");
const upload = require("../config/upload");
const favoriteController = require("../controllers/favoriteController");

router.post(
  "/",
  verifyToken,
  upload.array("images", 10),
  productController.createProduct,
);
router.get("/groups/:id", productController.getProductsByGroup); // GET /products/groups/:id
router.get("/general", productController.getGeneralList);
router.get("/point", productController.getPointList);
router.get("/auctions", productController.getAuctionList);
router.get("/:id/related-category", productController.getRelatedByCategory);
router.get("/:id/related-seller", productController.getRelatedBySeller);
router.get("/:id", productController.getProductDetail);
router.post("/:id/favorite", verifyToken, favoriteController.toggleFavorite); // POST /products/:id/favorite
// src/routes/productRoutes.js
router.get("/me/selling", verifyToken, productController.getMySellingGeneral); // GET /products/me/selling
router.get("/me/sold", verifyToken, productController.getMySoldGeneral); // GET /products/me/sold
router.get(
  "/me/auctions/selling",
  verifyToken,
  productController.getMySellingAuction,
); // GET /products/me/auctions/selling
router.get(
  "/me/auctions/sold",
  verifyToken,
  productController.getMySoldAuction,
); // GET /products/me/auctions/sold

router.get(
  "/me/recent/general",
  verifyToken,
  productController.getRecentViewedGeneral,
); // GET /products/me/recent/general
router.get(
  "/me/recent/auctions",
  verifyToken,
  productController.getRecentViewedAuction,
); // GET /products/me/recent/auctions

router.get(
  "/me/bidding/ongoing",
  verifyToken,
  productController.getMyBiddingOngoing,
); // GET /products/me/bidding/ongoing
router.get("/me/bidding/won", verifyToken, productController.getMyBiddingWon); // GET /products/me/bidding/won
router.get("/me/bidding/lost", verifyToken, productController.getMyBiddingLost); // GET /products/me/bidding/lost
router.get("/auctions/:id", productController.getAuctionDetail); // GET /products/auctions/:id
router.get("/auctions/:id/participants", bidController.getAuctionParticipants); // GET /products/auctions/:id/participants
router.get(
  "/me/favorites/general",
  verifyToken,
  productController.getFavoritedGeneral,
); // GET /products/me/favorites/general
router.get(
  "/me/favorites/auctions",
  verifyToken,
  productController.getFavoritedAuction,
); // GET /products/me/favorites/auctions

router.post("/:id/bid", verifyToken, bidController.placeBid); // POST /products/:id/bid

module.exports = router;
