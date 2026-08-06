// src/models/productModel.js
const pool = require("../config/db");
const { getTemperatureLevel } = require("../utils/temperature");

exports.createProduct = async (userId, productData) => {
  const {
    title,
    description,
    type, // 'general' | 'point' | 'auction'
    money_price,
    point_price,
    category_id,
    location,
    latitude,
    longitude,
    images, // 배열: ['url1', 'url2']
    auction, // { start_point, end_date } - type이 auction일 때만
  } = productData;

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [product] = await connection.query(
      `INSERT INTO products
        (user_id, title, description, money_price, point_price, type, category_id, location, latitude, longitude)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        title,
        description || null,
        type === "general" ? money_price : null,
        type === "point" ? point_price : null,
        type,
        category_id || null,
        location,
        latitude,
        longitude,
      ],
    );

    const productId = product.insertId;

    // 타입별 분기 처리
    if (type === "auction") {
      if (!auction || !auction.start_point || !auction.end_date) {
        throw new Error("AUCTION_FIELDS_REQUIRED");
      }

      await connection.query(
        `INSERT INTO auction (product_id, start_point, end_date, highest_point)
         VALUES (?, ?, ?, ?)`,
        [productId, auction.start_point, auction.end_date, auction.start_point],
      );
    }

    // 이미지 등록 (공통)
    if (Array.isArray(images) && images.length > 0) {
      const values = images.map((img) => [img, productId]);
      await connection.query(
        `INSERT INTO product_images (img, product_id) VALUES ?`,
        [values],
      );
    }

    await connection.commit();

    return productId;
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
};

exports.getProductById = async (productId) => {
  const [rows] = await pool.query(
    `SELECT p.*, c.name AS category_name
     FROM products p
     LEFT JOIN category c ON c.id = p.category_id
     WHERE p.id = ?`,
    [productId],
  );
  return rows[0];
};

const SORT_MAP = {
  likes: "favoriteCount DESC",
  newest: "p.created_at DESC",
  oldest: "p.created_at ASC",
  name: "p.title ASC",
};

const getSortClause = (sort) => SORT_MAP[sort] || SORT_MAP.newest; // 기본값: 최신순

// 일반거래 목록
exports.getGeneralList = async (sort, location) => {
  const params = [];
  const locationClause = location ? "AND p.location = ?" : "";
  if (location) params.push(location);

  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.money_price AS price, p.location,
       COUNT(f.id) AS favoriteCount
     FROM products p
     LEFT JOIN favorites f ON f.product_id = p.id
     WHERE p.type = 'general' AND p.status = 'sale'
       ${locationClause}
     GROUP BY p.id
     ORDER BY ${getSortClause(sort)}`,
    params,
  );
  return rows;
};

// 포인트거래 목록
exports.getPointList = async (sort, location) => {
  const params = [];
  const locationClause = location ? "AND p.location = ?" : "";
  if (location) params.push(location);

  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.point_price AS price, p.location,
       COUNT(f.id) AS favoriteCount
     FROM products p
     LEFT JOIN favorites f ON f.product_id = p.id
     WHERE p.type = 'point' AND p.status = 'sale'
       ${locationClause}
     GROUP BY p.id
     ORDER BY ${getSortClause(sort)}`,
    params,
  );
  return rows;
};

// 경매 목록
exports.getAuctionList = async (sort, location) => {
  const params = [];
  const locationClause = location ? "AND p.location = ?" : "";
  if (location) params.push(location);

  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, a.end_date, a.highest_point,
       COUNT(f.id) AS favoriteCount
     FROM auction a
     JOIN products p ON p.id = a.product_id
     LEFT JOIN favorites f ON f.product_id = p.id
     WHERE 1=1
       ${locationClause}
     GROUP BY p.id
     ORDER BY ${getSortClause(sort)}`,
    params,
  );

  const now = new Date();
  return rows.map((row) => {
    const diffMs = new Date(row.end_date) - now;
    const isOngoing = diffMs > 0;
    let remaining = "00:00";
    if (isOngoing) {
      const totalMinutes = Math.floor(diffMs / 60000);
      const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
      const minutes = String(totalMinutes % 60).padStart(2, "0");
      remaining = `${hours}:${minutes}`;
    }
    return {
      id: row.id,
      title: row.title,
      isOngoing,
      remaining,
      highestPoint: row.highest_point,
      favoriteCount: row.favoriteCount,
    };
  });
};

// 상품 세부 정보 불러오기 (세부 페이지)
exports.getProductDetail = async (productId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.description, p.money_price, p.point_price, p.type, p.created_at,
       u.name AS user_name, u.temperature,
       loc.city,
       c.name AS category_name,
       (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount,
       (SELECT COUNT(*) FROM rooms r WHERE r.product_id = p.id) AS chatCount
     FROM products p
     JOIN users u ON u.id = p.user_id
     LEFT JOIN location loc ON loc.id = u.location_id
     LEFT JOIN category c ON c.id = p.category_id
     WHERE p.id = ?`,
    [productId],
  );

  const product = rows[0];
  if (!product) return null;

  const [images] = await pool.query(
    `SELECT img FROM product_images WHERE product_id = ?`,
    [productId],
  );

  const diffDays = Math.floor(
    (new Date() - new Date(product.created_at)) / (1000 * 60 * 60 * 24),
  );

  return {
    id: product.id,
    title: product.title,
    description: product.description,
    price:
      product.type === "general" ? product.money_price : product.point_price,
    userName: product.user_name,
    temperature: product.temperature,
    temperatureLevel: getTemperatureLevel(product.temperature),
    location: product.city,
    createdDaysAgo: `${diffDays}일`,
    category: product.category_name,
    images: images.map((row) => row.img),
    favoriteCount: product.favoriteCount,
    chatCount: product.chatCount,
  };
};

// TODO: 경매 세부 페이지 디자인 확정 후 구현
// exports.getAuctionDetail = async (productId) => {
//   const [rows] = await pool.query(
//     `SELECT
//        p.id, p.title, p.description,
//        a.start_point, a.end_date, a.highest_point, a.highest_user,
//        u.name AS user_name,
//        c.name AS category_name
//      FROM products p
//      JOIN auction a ON a.product_id = p.id
//      JOIN users u ON u.id = p.user_id
//      LEFT JOIN category c ON c.id = p.category_id
//      WHERE p.id = ?`,
//     [productId],
//   );
//   return rows[0];
// };

// 같은 카테고리의 다른 상품 (같은 타입만)
exports.getRelatedByCategory = async (productId) => {
  const [current] = await pool.query(
    `SELECT category_id, type FROM products WHERE id = ?`,
    [productId],
  );

  if (current.length === 0) return [];

  const { category_id, type } = current[0];

  if (!category_id) return []; // 카테고리 없는 상품(경매 등)이면 빈 배열

  const [rows] = await pool.query(
    `SELECT
       p.id, p.title,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     WHERE p.category_id = ? AND p.type = ? AND p.id != ? AND p.status = 'sale'
     ORDER BY p.created_at DESC`,
    [category_id, type, productId],
  );

  return rows;
};

// 같은 판매자의 다른 상품 (같은 타입만)
exports.getRelatedBySeller = async (productId) => {
  const [current] = await pool.query(
    `SELECT user_id, type FROM products WHERE id = ?`,
    [productId],
  );

  if (current.length === 0) return [];

  const { user_id, type } = current[0];

  const [rows] = await pool.query(
    `SELECT
       p.id, p.title,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     WHERE p.user_id = ? AND p.type = ? AND p.id != ? AND p.status = 'sale'
     ORDER BY p.created_at DESC`,
    [user_id, type, productId],
  );

  return rows;
};

exports.searchProducts = async (keyword) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.type, p.money_price, p.point_price,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     WHERE p.title LIKE ? AND p.status = 'sale'
     ORDER BY p.created_at DESC`,
    [`%${keyword}%`],
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    type: row.type,
    price:
      row.type === "general"
        ? row.money_price
        : row.type === "point"
          ? row.point_price
          : null,
    img: row.img,
  }));
};

exports.getProductsByGroup = async (groupId) => {
  const [rows] = await pool.query(
    `SELECT p.id, p.title, p.money_price, p.point_price, p.type,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     JOIN category c ON c.id = p.category_id
     WHERE c.group_id = ? AND p.status = 'sale'
     ORDER BY p.created_at DESC`,
    [groupId],
  );
  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    price:
      row.type === "general"
        ? row.money_price
        : row.type === "point"
          ? row.point_price
          : null,
    type: row.type,
    img: row.img,
  }));
};

exports.getMySellingGeneral = async (userId, status) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.type, p.money_price, p.point_price, p.status,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
       (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount
     FROM products p
     WHERE p.user_id = ? AND p.type IN ('general', 'point') AND p.status = ?
     ORDER BY p.created_at DESC`,
    [userId, status],
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    price: row.type === "general" ? row.money_price : row.point_price,
    img: row.img,
    favoriteCount: row.favoriteCount,
  }));
};

exports.getMySellingAuction = async (userId, isOngoing) => {
  const comparison = isOngoing ? "a.end_date > NOW()" : "a.end_date <= NOW()";

  const [rows] = await pool.query(
    `SELECT p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
       (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount
     FROM products p
     JOIN auction a ON a.product_id = p.id
     WHERE p.user_id = ? AND ${comparison}
     ORDER BY a.end_date ASC`,
    [userId],
  );

  const now = new Date();

  return rows.map((row) => {
    const diffMs = new Date(row.end_date) - now;
    let remaining = "00:00";
    if (diffMs > 0) {
      const totalMinutes = Math.floor(diffMs / 60000);
      const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
      const minutes = String(totalMinutes % 60).padStart(2, "0");
      remaining = `${hours}:${minutes}`;
    }

    return {
      id: row.id,
      title: row.title,
      img: row.img,
      highestPoint: row.highest_point,
      remaining,
      favoriteCount: row.favoriteCount,
    };
  });
};

// 2-1. 최근 본 일반 상품(general+point)
exports.getRecentViewedGeneral = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.type, p.money_price, p.point_price,
       c.name AS categoryName,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
       MAX(vp.date) AS viewedAt
     FROM view_product vp
     JOIN products p ON p.id = vp.product_id
     LEFT JOIN category c ON c.id = p.category_id
     WHERE vp.user_id = ? AND p.type IN ('general', 'point')
     GROUP BY p.id
     ORDER BY viewedAt DESC`,
    [userId],
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    price: row.type === "general" ? row.money_price : row.point_price,
    img: row.img,
    categoryName: row.categoryName,
  }));
};

// 2-2. 최근 본 경매
exports.getRecentViewedAuction = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
       MAX(vp.date) AS viewedAt
     FROM view_product vp
     JOIN products p ON p.id = vp.product_id
     JOIN auction a ON a.product_id = p.id
     WHERE vp.user_id = ?
     GROUP BY p.id
     ORDER BY viewedAt DESC`,
    [userId],
  );

  const now = new Date();

  return rows.map((row) => {
    const diffMs = new Date(row.end_date) - now;
    let remaining = "00:00";
    if (diffMs > 0) {
      const totalMinutes = Math.floor(diffMs / 60000);
      const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
      const minutes = String(totalMinutes % 60).padStart(2, "0");
      remaining = `${hours}:${minutes}`;
    }
    return {
      id: row.id,
      title: row.title,
      img: row.img,
      highestPoint: row.highest_point,
      remaining,
    };
  });
};

// 조회 기록 저장 (상품 상세 조회 시 호출)
exports.logProductView = async (userId, productId) => {
  await pool.query(
    `INSERT INTO view_product (user_id, product_id) VALUES (?, ?)`,
    [userId, productId],
  );
};

// 3-1. 좋아요한 일반 상품
exports.getFavoritedGeneral = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.type, p.money_price, p.point_price,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM favorites f
     JOIN products p ON p.id = f.product_id
     WHERE f.user_id = ? AND p.type IN ('general', 'point')
     ORDER BY f.id DESC`,
    [userId],
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    price: row.type === "general" ? row.money_price : row.point_price,
    img: row.img,
  }));
};

// 3-2. 좋아요한 경매
exports.getFavoritedAuction = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM favorites f
     JOIN products p ON p.id = f.product_id
     JOIN auction a ON a.product_id = p.id
     WHERE f.user_id = ?
     ORDER BY f.id DESC`,
    [userId],
  );

  const now = new Date();

  return rows.map((row) => {
    const diffMs = new Date(row.end_date) - now;
    let remaining = "00:00";
    if (diffMs > 0) {
      const totalMinutes = Math.floor(diffMs / 60000);
      const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
      const minutes = String(totalMinutes % 60).padStart(2, "0");
      remaining = `${hours}:${minutes}`;
    }
    return {
      id: row.id,
      title: row.title,
      img: row.img,
      highestPoint: row.highest_point,
      remaining,
    };
  });
};

// src/models/productModel.js에 추가

// 4-2-1. 내가 입찰한 경매 - 진행 중
exports.getMyBiddingOngoing = async (userId) => {
  const [rows] = await pool.query(
    `SELECT DISTINCT
       p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM bids b
     JOIN auction a ON a.product_id = b.auction_id
     JOIN products p ON p.id = a.product_id
     WHERE b.user_id = ? AND a.end_date > NOW()
     ORDER BY a.end_date ASC`,
    [userId],
  );

  return rows.map((row) => formatAuctionRow(row));
};

// 4-2-2. 내가 입찰한 경매 - 낙찰 성공 (종료 + 내가 최고 입찰자)
exports.getMyBiddingWon = async (userId) => {
  const [rows] = await pool.query(
    `SELECT DISTINCT
       p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM bids b
     JOIN auction a ON a.product_id = b.auction_id
     JOIN products p ON p.id = a.product_id
     WHERE b.user_id = ? AND a.end_date <= NOW() AND a.highest_user = ?
     ORDER BY a.end_date DESC`,
    [userId, userId],
  );

  return rows.map((row) => formatAuctionRow(row));
};

// 4-2-3. 내가 입찰한 경매 - 낙찰 실패 (종료 + 내가 최고 입찰자 아님)
exports.getMyBiddingLost = async (userId) => {
  const [rows] = await pool.query(
    `SELECT DISTINCT
       p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM bids b
     JOIN auction a ON a.product_id = b.auction_id
     JOIN products p ON p.id = a.product_id
     WHERE b.user_id = ? AND a.end_date <= NOW()
       AND (a.highest_user IS NULL OR a.highest_user != ?)
     ORDER BY a.end_date DESC`,
    [userId, userId],
  );

  return rows.map((row) => formatAuctionRow(row));
};

// 공통 포맷 함수 (remaining 계산 포함)
function formatAuctionRow(row) {
  const now = new Date();
  const diffMs = new Date(row.end_date) - now;
  let remaining = "00:00";
  if (diffMs > 0) {
    const totalMinutes = Math.floor(diffMs / 60000);
    const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
    const minutes = String(totalMinutes % 60).padStart(2, "0");
    remaining = `${hours}:${minutes}`;
  }
  return {
    id: row.id,
    title: row.title,
    img: row.img,
    highestPoint: row.highest_point,
    remaining,
  };
}

exports.getAuctionDetail = async (productId) => {
  const [[auction]] = await pool.query(
    `SELECT
       p.id, p.title, p.description, p.category_id,
       a.end_date, a.start_point, a.highest_point, a.highest_user,
       u.name AS sellerName, u.img AS sellerImg, u.temperature AS sellerTemperature,
       loc.city AS sellerCity,
       c.name AS categoryName,
       (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount,
       (SELECT COUNT(DISTINCT b.user_id) FROM bids b WHERE b.auction_id = p.id) AS participantCount
     FROM products p
     JOIN auction a ON a.product_id = p.id
     JOIN users u ON u.id = p.user_id
     LEFT JOIN location loc ON loc.id = u.location_id
     LEFT JOIN category c ON c.id = p.category_id
     WHERE p.id = ?`,
    [productId],
  );

  if (!auction) return null;

  const [images] = await pool.query(
    `SELECT img FROM product_images WHERE product_id = ?`,
    [productId],
  );

  // 최고 입찰자 프로필 이미지
  let highestBidderImg = null;
  if (auction.highest_user) {
    const [[bidder]] = await pool.query(`SELECT img FROM users WHERE id = ?`, [
      auction.highest_user,
    ]);
    highestBidderImg = bidder ? bidder.img : null;
  }

  // 관련 상품: 같은 카테고리의 다른 경매 상품
  const [related] = await pool.query(
    `SELECT p.id, p.title,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     JOIN auction a2 ON a2.product_id = p.id
     WHERE p.category_id = ? AND p.id != ? AND a2.end_date > NOW()
     ORDER BY p.created_at DESC`,
    [auction.category_id, productId],
  );

  // 남은 시간: "00h 00m left" 포맷
  const diffMs = new Date(auction.end_date) - new Date();
  let remaining = "00h 00m left";
  if (diffMs > 0) {
    const totalMinutes = Math.floor(diffMs / 60000);
    const hours = String(Math.floor(totalMinutes / 60)).padStart(2, "0");
    const minutes = String(totalMinutes % 60).padStart(2, "0");
    remaining = `${hours}h ${minutes}m left`;
  }

  return {
    id: auction.id,
    title: auction.title,
    description: auction.description,
    category: auction.categoryName,
    images: images.map((row) => row.img),
    favoriteCount: auction.favoriteCount,
    remaining,
    seller: {
      name: auction.sellerName,
      img: auction.sellerImg,
      city: auction.sellerCity,
      temperatureLevel: getTemperatureLevel(auction.sellerTemperature),
    },
    highestBid: {
      point: auction.highest_point,
      bidderImg: highestBidderImg,
    },
    participantCount: auction.participantCount,
    relatedProducts: related.map((row) => ({
      id: row.id,
      title: row.title,
      img: row.img,
    })),
  };
};
