const pool = require("../config/db");
const { getTemperatureLevel } = require("../utils/temperature");

exports.getProfile = async (userId) => {
  const [[user]] = await pool.query(
    `SELECT name, img, temperature, point FROM users WHERE id = ?`,
    [userId],
  );

  if (!user) return null;

  const [[earned]] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total
     FROM point_history
     WHERE user_id = ? AND type = 'earn_sale'`,
    [userId],
  );

  const [[counts]] = await pool.query(
    `SELECT
       SUM(CASE WHEN buyer_id = ? THEN 1 ELSE 0 END) AS boughtCount,
       SUM(CASE WHEN seller_id = ? THEN 1 ELSE 0 END) AS soldCount
     FROM trades
     WHERE status = 'completed' AND (buyer_id = ? OR seller_id = ?)`,
    [userId, userId, userId, userId],
  );

  const [[co2]] = await pool.query(
    `SELECT COALESCE(SUM(c.co2_saved), 0) AS totalCo2
     FROM trades t
     JOIN products p ON p.id = t.product_id
     LEFT JOIN category c ON c.id = p.category_id
     WHERE t.status = 'completed' AND (t.buyer_id = ? OR t.seller_id = ?)`,
    [userId, userId],
  );

  return {
    name: user.name,
    img: user.img,
    temperature: user.temperature,
    temperatureLevel: getTemperatureLevel(user.temperature),
    point: user.point,
    totalEarnedPoint: earned.total,
    boughtCount: counts.boughtCount || 0,
    soldCount: counts.soldCount || 0,
    co2SavedKg: Number(co2.totalCo2),
  };
};

exports.updateLocation = async (userId, locationId) => {
  const [result] = await pool.query(
    `UPDATE users SET location_id = ? WHERE id = ?`,
    [locationId, userId],
  );
  return result.affectedRows;
};

exports.updateProfileImage = async (userId, imgUrl) => {
  await pool.query(`UPDATE users SET img = ? WHERE id = ?`, [imgUrl, userId]);
};

const { getTemperatureLevel } = require("../utils/temperature");

exports.getPublicProfile = async (userId) => {
  const [[user]] = await pool.query(
    `SELECT name, img, temperature, last_active_at FROM users WHERE id = ?`,
    [userId],
  );

  if (!user) return null;

  const [categories] = await pool.query(
    `SELECT c.name FROM user_category uc JOIN category c ON c.id = uc.category_id WHERE uc.user_id = ?`,
    [userId],
  );

  const [sellingProducts] = await pool.query(
    `SELECT p.id, p.title, p.money_price, p.point_price, p.type,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     WHERE p.user_id = ? AND p.type IN ('general', 'point') AND p.status = 'sale'
     ORDER BY p.created_at DESC`,
    [userId],
  );

  const [auctionProducts] = await pool.query(
    `SELECT p.id, p.title, a.end_date, a.highest_point,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img
     FROM products p
     JOIN auction a ON a.product_id = p.id
     WHERE p.user_id = ? AND a.end_date > NOW()
     ORDER BY a.end_date ASC`,
    [userId],
  );

  const hoursAgo = Math.floor(
    (new Date() - new Date(user.last_active_at)) / (1000 * 60 * 60),
  );

  return {
    name: user.name,
    img: user.img,
    temperature: user.temperature,
    temperatureLevel: getTemperatureLevel(user.temperature),
    lastActiveHoursAgo: `${hoursAgo}시간 전`,
    categories: categories.map((row) => row.name),
    sellingProducts: sellingProducts.map((row) => ({
      id: row.id,
      title: row.title,
      price: row.type === "general" ? row.money_price : row.point_price,
      img: row.img,
    })),
    auctionProducts: auctionProducts.map((row) => ({
      id: row.id,
      title: row.title,
      highestPoint: row.highest_point,
      img: row.img,
    })),
  };
};
