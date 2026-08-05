// src/models/bidModel.js
const pool = require("../config/db");

exports.placeBid = async (userId, productId, point) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [[auction]] = await connection.query(
      `SELECT product_id, start_point, end_date, highest_user, highest_point
       FROM auction WHERE product_id = ? FOR UPDATE`,
      [productId],
    );

    if (!auction) throw new Error("AUCTION_NOT_FOUND");
    if (new Date(auction.end_date) <= new Date())
      throw new Error("AUCTION_ENDED");

    const minRequired = auction.highest_point
      ? auction.highest_point + 1
      : auction.start_point;
    if (point < minRequired) throw new Error("BID_TOO_LOW");

    const previousHighestUser = auction.highest_user;
    const previousHighestPoint = auction.highest_point;

    const lockDelta =
      previousHighestUser === userId
        ? point - previousHighestPoint // 본인이 이미 최고 입찰자 → 차액만
        : point; // 새로 전체 금액 잠금

    const [[user]] = await connection.query(
      `SELECT point, lock_point FROM users WHERE id = ? FOR UPDATE`,
      [userId],
    );

    const available = user.point - user.lock_point;
    if (available < lockDelta) throw new Error("INSUFFICIENT_POINT");

    await connection.query(
      `UPDATE users SET lock_point = lock_point + ? WHERE id = ?`,
      [lockDelta, userId],
    );

    if (previousHighestUser && previousHighestUser !== userId) {
      await connection.query(
        `UPDATE users SET lock_point = lock_point - ? WHERE id = ?`,
        [previousHighestPoint, previousHighestUser],
      );
    }

    await connection.query(
      `INSERT INTO bids (auction_id, user_id, point) VALUES (?, ?, ?)`,
      [productId, userId, point],
    );
    await connection.query(
      `UPDATE auction SET highest_point = ?, highest_user = ? WHERE product_id = ?`,
      [point, userId, productId],
    );

    await connection.commit();
    return { highestPoint: point };
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
};

exports.getAuctionParticipants = async (productId) => {
  const [rows] = await pool.query(
    `SELECT
       b.user_id, u.name, u.img, b.point, b.created_at,
       a.highest_user
     FROM bids b
     JOIN users u ON u.id = b.user_id
     JOIN auction a ON a.product_id = b.auction_id
     INNER JOIN (
       SELECT user_id, MAX(id) AS latestBidId
       FROM bids
       WHERE auction_id = ?
       GROUP BY user_id
     ) latest ON latest.latestBidId = b.id
     WHERE b.auction_id = ?
     ORDER BY b.point DESC`,
    [productId, productId],
  );

  const now = new Date();

  return rows.map((row) => {
    const hoursAgo = Math.floor(
      (now - new Date(row.created_at)) / (1000 * 60 * 60),
    );
    return {
      userName: row.name,
      userImg: row.img,
      point: row.point,
      bidHoursAgo: `${hoursAgo} hours ago`,
      isHighest: row.user_id === row.highest_user,
    };
  });
};
