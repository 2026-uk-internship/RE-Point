const pool = require("../config/db");

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

// 일반 상품 불러오기
exports.getMainList = async () => {
  const [rows] = await pool.query(
    `SELECT id, title, type, money_price, point_price, location
     FROM products
     WHERE type IN ('general', 'point') AND status = 'sale'
     ORDER BY created_at DESC`,
  );

  return rows.map((row) => ({
    id: row.id,
    title: row.title,
    price: row.type === "general" ? row.money_price : row.point_price,
    type: row.type,
    location: row.location,
  }));
};

// 경매 상품 불러오기
exports.getAuctionList = async () => {
  const [rows] = await pool.query(
    `SELECT p.id, p.title, a.end_date, a.highest_point
     FROM auction a
     JOIN products p ON p.id = a.product_id
     ORDER BY a.end_date ASC`,
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
      remaining, // "00:00" 형식
      highestPoint: row.highest_point,
    };
  });
};

// 상품 세부 정보 불러오기 (세부 페이지)
exports.getProductDetail = async (productId) => {
  const [rows] = await pool.query(
    `SELECT
       p.id, p.title, p.description, p.money_price, p.point_price, p.type, p.created_at,
       u.name AS user_name, u.temperature,
       loc.country, loc.region, loc.city,
       c.name AS category_name
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
    location: `${product.region} ${product.city}`,
    createdDaysAgo: `${diffDays}일`,
    category: product.category_name,
    images: images.map((row) => row.img),
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
