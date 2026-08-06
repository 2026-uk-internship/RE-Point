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
  // auction 테이블 LEFT JOIN 추가:
  // - location, end_date, highest_point는 경매 검색 결과 카드(위치/남은시간/현재입찰가)에 필요한 필드
  // - LEFT JOIN인 이유: general/point 상품은 auction 레코드가 없으므로 a.* 컬럼이 전부 NULL로 채워짐 (정상)
  const baseSelect = `
    SELECT
      p.id, p.title, p.money_price, p.point_price, p.type, p.created_at,
      p.location,
      a.end_date,
      a.highest_point,
      (SELECT pi.img FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.id ASC LIMIT 1) AS img,
      (SELECT COUNT(*) FROM favorites f WHERE f.product_id = p.id) AS favoriteCount,
      (SELECT COUNT(*) FROM rooms r WHERE r.product_id = p.id) AS chatCount
    FROM products p
    LEFT JOIN auction a ON a.product_id = p.id
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
    // 경매 상품일 때만 의미 있는 필드 (general/point는 항상 null)
    location: row.type === "auction" ? row.location : null,
    endDate: row.type === "auction" && row.end_date ? row.end_date : null,
    highestPoint: row.type === "auction" ? row.highest_point : null,
  });

  return {
    generalAndPoint: generalPoint.map(formatItem),
    auction: auctionRows.map(formatItem),
  };
};
