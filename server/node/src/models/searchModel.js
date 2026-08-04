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
