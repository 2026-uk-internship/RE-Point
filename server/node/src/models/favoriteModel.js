const pool = require("../config/db");

exports.toggleFavorite = async (userId, productId) => {
  const [existing] = await pool.query(
    `SELECT id FROM favorites WHERE user_id = ? AND product_id = ?`,
    [userId, productId],
  );

  if (existing.length > 0) {
    await pool.query(`DELETE FROM favorites WHERE id = ?`, [existing[0].id]);
    return { favorited: false };
  }

  await pool.query(
    `INSERT INTO favorites (user_id, product_id) VALUES (?, ?)`,
    [userId, productId],
  );
  return { favorited: true };
};
