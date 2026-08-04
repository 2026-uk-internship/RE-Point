const productModel = require("../models/productModel");

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
      auction,
    } = req.body;

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
    const { sort } = req.query; // ?sort=likes
    const products = await productModel.getGeneralList(sort);
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
    const { sort } = req.query;
    const products = await productModel.getPointList(sort);
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
    const { sort } = req.query;
    const auctions = await productModel.getAuctionList(sort);
    return res.status(200).json({ data: auctions });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 상품 세부 정보 불러오기 (세부 페이지)
exports.getProductDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await productModel.getProductDetail(id);

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

// TODO: 경매 세부 페이지 디자인 확정 후 구현
// exports.getAuctionDetail = async (req, res) => {
//   ...
// };

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
