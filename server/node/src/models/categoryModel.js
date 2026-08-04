const pool = require("../config/db");

// 전체 카테고리 목록 조회 (상품 등록 시에도 재사용)
exports.getAllCategories = async () => {
  const [rows] = await pool.query(
    `SELECT id, name, point_rate FROM category ORDER BY name`,
  );
  return rows;
};

// 특정 사용자가 선택한 카테고리 조회
exports.getUserCategories = async (userId) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.name, c.point_rate
     FROM user_category uc
     JOIN category c ON c.id = uc.category_id
     WHERE uc.user_id = ?`,
    [userId],
  );
  return rows;
};

// 사용자 카테고리 저장 (기존 선택 전체를 새 목록으로 교체)
exports.setUserCategories = async (userId, categoryIds) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    await connection.query(`DELETE FROM user_category WHERE user_id = ?`, [
      userId,
    ]);

    if (categoryIds.length > 0) {
      const values = categoryIds.map((categoryId) => [userId, categoryId]);
      await connection.query(
        `INSERT INTO user_category (user_id, category_id) VALUES ?`,
        [values],
      );
    }

    await connection.commit();
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
};
