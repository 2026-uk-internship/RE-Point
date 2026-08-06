const pool = require("../config/db");

exports.findOrCreateRoom = async (productId, buyerId) => {
  const [product] = await pool.query(
    `SELECT user_id AS sellerId FROM products WHERE id = ?`,
    [productId],
  );

  if (product.length === 0) {
    throw new Error("PRODUCT_NOT_FOUND");
  }

  const sellerId = product[0].sellerId;

  if (sellerId === buyerId) {
    throw new Error("CANNOT_CHAT_WITH_SELF");
  }

  const [existing] = await pool.query(
    `SELECT id FROM rooms WHERE product_id = ? AND buyer = ? AND seller = ?`,
    [productId, buyerId, sellerId],
  );

  if (existing.length > 0) return existing[0].id;

  const [result] = await pool.query(
    `INSERT INTO rooms (seller, buyer, product_id) VALUES (?, ?, ?)`,
    [sellerId, buyerId, productId],
  );

  return result.insertId;
};

exports.getRoomList = async (userId, keyword) => {
  const conditions = ["(r.seller = ? OR r.buyer = ?)"];
  const params = [userId, userId, userId, userId];

  if (keyword) {
    conditions.push("u.name LIKE ?");
    params.push(`%${keyword}%`);
  }

  const [rows] = await pool.query(
    `SELECT
       r.id AS roomId,
       CASE WHEN r.seller = ? THEN r.buyer ELSE r.seller END AS counterpartId,
       u.name AS counterpartName,
       u.img AS counterpartImg,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = r.product_id ORDER BY pi.id ASC LIMIT 1) AS productImg,
       (SELECT c.message FROM chats c WHERE c.room_id = r.id ORDER BY c.date DESC LIMIT 1) AS lastMessage,
       (SELECT c.date FROM chats c WHERE c.room_id = r.id ORDER BY c.date DESC LIMIT 1) AS lastMessageDate
     FROM rooms r
     JOIN users u ON u.id = (CASE WHEN r.seller = ? THEN r.buyer ELSE r.seller END)
     WHERE ${conditions.join(" AND ")}
     ORDER BY lastMessageDate DESC`,
    params,
  );

  const now = new Date();

  return rows.map((row) => {
    let hoursAgo = null;
    if (row.lastMessageDate) {
      const diffMs = now - new Date(row.lastMessageDate);
      hoursAgo = Math.floor(diffMs / (1000 * 60 * 60));
    }

    return {
      roomId: row.roomId,
      counterpartName: row.counterpartName,
      counterpartImg: row.counterpartImg,
      productImg: row.productImg,
      lastMessage: row.lastMessage,
      lastMessageHoursAgo: hoursAgo !== null ? `${hoursAgo}h ago` : null,
    };
  });
};

exports.getRoomInfo = async (roomId, userId) => {
  const [rows] = await pool.query(
    `SELECT
       (CASE WHEN r.seller = ? THEN u2.name ELSE u1.name END) AS counterpartName,
       (CASE WHEN r.seller = ? THEN u2.temperature ELSE u1.temperature END) AS counterpartTemperature,
       (SELECT pi.img FROM product_images pi WHERE pi.product_id = r.product_id ORDER BY pi.id ASC LIMIT 1) AS productImg
     FROM rooms r
     JOIN users u1 ON u1.id = r.seller
     JOIN users u2 ON u2.id = r.buyer
     WHERE r.id = ?`,
    [userId, userId, roomId],
  );
  return rows[0];
};
