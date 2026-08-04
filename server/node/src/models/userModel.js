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

// src/models/userModel.js에 추가
exports.updateLocation = async (userId, locationId) => {
  const [result] = await pool.query(
    `UPDATE users SET location_id = ? WHERE id = ?`,
    [locationId, userId],
  );
  return result.affectedRows;
};
