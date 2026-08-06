// src/controllers/productController.js
const productModel = require("../models/productModel");
const jwt = require("jsonwebtoken");

exports.createProduct = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      title,
      description,
      type,
      money_price,
      point_price,
      category_id,
      location,
      latitude,
      longitude,
      start_point,
      end_date,
    } = req.body;

    let auction = null;

    if (type === "auction") {
      auction = {
        start_point,
        end_date,
      };
    }

    if (!title || !type || !location || latitude == null || longitude == null) {
      return res.status(400).json({ message: "Required fields are missing." });
    }

    // multer가 업로드된 파일들을 req.files에 담아줌 — 각 파일의 Cloudinary URL은 file.path
    const imageUrls = (req.files || []).map((file) => file.path);

    const productId = await productModel.createProduct(userId, {
      title,
      description,
      type,
      money_price,
      point_price,
      category_id,
      location,
      latitude,
      longitude,
      images: imageUrls, // 기존 모델 코드 그대로 재사용 가능
      auction,
    });

    return res.status(201).json({
      message: "Product created successfully.",
      data: { id: productId },
    });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await productModel.getProductById(id);

    if (!product) {
      return res.status(404).json({ message: "Product not found." });
    }

    return res.status(200).json({ data: product });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getGeneralList = async (req, res) => {
  try {
    const { sort, location } = req.query;
    const products = await productModel.getGeneralList(sort, location);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getPointList = async (req, res) => {
  try {
    const { sort, location } = req.query;
    const products = await productModel.getPointList(sort, location);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getAuctionList = async (req, res) => {
  try {
    const { sort, location } = req.query;
    const auctions = await productModel.getAuctionList(sort, location);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 상품 세부 정보 불러오기 (세부 페이지)
// src/controllers/productController.js — getProductDetail 안에 추가
exports.getProductDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await productModel.getProductDetail(id);

    if (!product) {
      return res.status(404).json({ message: "Product not found." });
    }

    // 로그인한 사용자면 조회 기록 저장 (비로그인 조회는 기록 안 함)
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      try {
        const decoded = jwt.verify(
          authHeader.split(" ")[1],
          process.env.JWT_SECRET,
        );
        await productModel.logProductView(decoded.id, id);
      } catch (e) {
        // 토큰이 유효하지 않아도 상세 조회 자체는 그대로 진행
      }
    }

    return res.status(200).json({ data: product });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getRelatedByCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const products = await productModel.getRelatedByCategory(id);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getRelatedBySeller = async (req, res) => {
  try {
    const { id } = req.params;
    const products = await productModel.getRelatedBySeller(id);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getProductsByGroup = async (req, res) => {
  try {
    const { id } = req.params;
    const products = await productModel.getProductsByGroup(id);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMySellingGeneral = async (req, res) => {
  try {
    const products = await productModel.getMySellingGeneral(
      req.user.id,
      "sale",
    );
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMySoldGeneral = async (req, res) => {
  try {
    const products = await productModel.getMySellingGeneral(
      req.user.id,
      "sold",
    );
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMySellingAuction = async (req, res) => {
  try {
    const auctions = await productModel.getMySellingAuction(req.user.id, true);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMySoldAuction = async (req, res) => {
  try {
    const auctions = await productModel.getMySellingAuction(req.user.id, false);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getRecentViewedGeneral = async (req, res) => {
  try {
    const products = await productModel.getRecentViewedGeneral(req.user.id);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getRecentViewedAuction = async (req, res) => {
  try {
    const auctions = await productModel.getRecentViewedAuction(req.user.id);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getFavoritedGeneral = async (req, res) => {
  try {
    const products = await productModel.getFavoritedGeneral(req.user.id);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getFavoritedAuction = async (req, res) => {
  try {
    const auctions = await productModel.getFavoritedAuction(req.user.id);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMyBiddingOngoing = async (req, res) => {
  try {
    const auctions = await productModel.getMyBiddingOngoing(req.user.id);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMyBiddingWon = async (req, res) => {
  try {
    const auctions = await productModel.getMyBiddingWon(req.user.id);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getMyBiddingLost = async (req, res) => {
  try {
    const auctions = await productModel.getMyBiddingLost(req.user.id);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getAuctionDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const auction = await productModel.getAuctionDetail(id);

    if (!auction) {
      return res.status(404).json({ message: "Auction not found." });
    }

    return res.status(200).json({ data: auction });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 거래 완료 처리 (판매자만 호출 가능)
// PATCH /products/:id/complete
// body: { buyerId } — general/point 타입일 때 필요. auction은 최고 입찰자로 자동 지정되므로 무시됨.
exports.completeTrade = async (req, res) => {
  try {
    const { id } = req.params;
    const sellerId = req.user.id;
    const { buyerId } = req.body;

    const result = await productModel.completeTrade(id, sellerId, buyerId);

    return res.status(200).json({
      message: "Trade completed successfully.",
      data: result,
    });
  } catch (err) {
    console.error(err);

    const errorMap = {
      PRODUCT_NOT_FOUND: [404, "Product not found."],
      NOT_OWNER: [403, "Only the seller can complete this trade."],
      ALREADY_COMPLETED: [409, "This product has already been sold."],
      NO_BIDDER: [400, "This auction has no bidder."],
      BUYER_REQUIRED: [400, "buyerId is required for this product type."],
      CANNOT_TRADE_WITH_SELF: [
        400,
        "Seller and buyer cannot be the same user.",
      ],
      INSUFFICIENT_POINTS: [400, "Buyer does not have enough points."],
    };

    const [status, message] = errorMap[err.message] || [
      500,
      "An internal server error occurred.",
    ];
    return res.status(status).json({ message });
  }
};
