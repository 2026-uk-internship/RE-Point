exports.findOrCreateRoom = async (productId, buyerId, sellerId) => {
  const [existing] = await pool.query(
    `SELECT id FROM rooms WHERE product_id = ? AND buyer = ? AND seller = ?`,
    [productId, buyerId, sellerId],
  );

  if (existing.length > 0) return existing[0].id;

  const [result] = await pool.query(
    `INSERT INTO rooms (product_id, buyer, seller) VALUES (?, ?, ?)`,
    [productId, buyerId, sellerId],
  );
  return result.insertId;
};
