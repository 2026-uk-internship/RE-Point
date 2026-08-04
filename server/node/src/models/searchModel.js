const pool = require("../config/db");

exports.logSearch = async (userId, keyword) => {
  // search 테이블에 있으면 count+1, 없으면 새로 추가
  const [existing] = await pool.query(`SELECT id FROM search WHERE title = ?`, [
    keyword,
  ]);

  let searchId;
  if (existing.length > 0) {
    searchId = existing[0].id;
    await pool.query(`UPDATE search SET count = count + 1 WHERE id = ?`, [
      searchId,
    ]);
  } else {
    const [result] = await pool.query(
      `INSERT INTO search (title, count) VALUES (?, 1)`,
      [keyword],
    );
    searchId = result.insertId;
  }

  // 사용자 검색 로그 추가 (매번 새로 기록 - 최신 검색 시각 갱신용)
  await pool.query(
    `INSERT INTO user_search_logs (user_id, search_id) VALUES (?, ?)`,
    [userId, searchId],
  );
};

exports.getRecentSearches = async (userId) => {
  const [rows] = await pool.query(
    `SELECT s.id AS searchId, s.title, MAX(usl.date) AS lastSearchedAt
     FROM user_search_logs usl
     JOIN search s ON s.id = usl.search_id
     WHERE usl.user_id = ?
     GROUP BY s.id
     ORDER BY lastSearchedAt DESC
     LIMIT 10`,
    [userId],
  );
  return rows;
};

exports.deleteRecentSearch = async (userId, searchId) => {
  const [result] = await pool.query(
    `DELETE FROM user_search_logs WHERE user_id = ? AND search_id = ?`,
    [userId, searchId],
  );
  return result.affectedRows;
};

exports.getPopularSearchesThisMonth = async () => {
  const [rows] = await pool.query(
    `SELECT s.title, COUNT(*) AS searchCount
     FROM user_search_logs usl
     JOIN search s ON s.id = usl.search_id
     WHERE usl.date >= DATE_FORMAT(NOW(), '%Y-%m-01')
     GROUP BY s.id
     ORDER BY searchCount DESC
     LIMIT 5`,
  );
  return rows.map((row) => row.title);
};

exports.searchProducts = async (keyword) => {
  const baseSelect = `
    SELECT
      p.id, p.title, p.money_price, p.point_price, p.type, p.created_at,
      (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
      (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount,
      (SELECT COUNT(*) FROM rooms r WHERE r.product_id = p.id) AS chatCount
    FROM products p
    WHERE p.title LIKE ? AND p.status = 'sale'
  `;

  const [generalPoint] = await pool.query(
    `${baseSelect} AND p.type IN ('general', 'point') ORDER BY p.created_at DESC`,
    [`%${keyword}%`],
  );

  const [auctionRows] = await pool.query(
    `${baseSelect} AND p.type = 'auction' ORDER BY p.created_at DESC`,
    [`%${keyword}%`],
  );

  const now = new Date();
  const daysAgo = (createdAt) =>
    `${Math.floor((now - new Date(createdAt)) / (1000 * 60 * 60 * 24))}일`;

  const formatItem = (row) => ({
    id: row.id,
    title: row.title,
    img: row.img,
    price:
      row.type === "general"
        ? row.money_price
        : row.type === "point"
          ? row.point_price
          : null,
    createdDaysAgo: daysAgo(row.created_at),
    favoriteCount: row.favoriteCount,
    chatCount: row.chatCount,
  });

  return {
    generalAndPoint: generalPoint.map(formatItem),
    auction: auctionRows.map(formatItem),
  };
};
