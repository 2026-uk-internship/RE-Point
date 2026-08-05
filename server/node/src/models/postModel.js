const pool = require("../config/db");

exports.createPost = async (userId, { title, contents, location }) => {
  const [result] = await pool.query(
    `INSERT INTO posts (title, contents, location, user_id) VALUES (?, ?, ?, ?)`,
    [title, contents, location, userId],
  );
  return result.insertId;
};

exports.getPostList = async (location) => {
  const conditions = [];
  const params = [];

  if (location) {
    conditions.push("p.location LIKE ?");
    params.push(`%${location}%`);
  }

  const whereClause =
    conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

  const [rows] = await pool.query(
    `SELECT p.id, p.title, p.location, p.date, u.name AS userName,
       (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS commentCount
     FROM posts p
     LEFT JOIN users u ON u.id = p.user_id
     ${whereClause}
     ORDER BY p.date DESC`,
    params,
  );
  return rows;
};

exports.getPostDetail = async (postId) => {
  const [rows] = await pool.query(
    `SELECT p.id, p.title, p.contents, p.location, p.date, u.name AS userName
     FROM posts p
     LEFT JOIN users u ON u.id = p.user_id
     WHERE p.id = ?`,
    [postId],
  );
  return rows[0];
};

exports.updatePost = async (postId, userId, { title, contents, location }) => {
  const [result] = await pool.query(
    `UPDATE posts SET title = ?, contents = ?, location = ? WHERE id = ? AND user_id = ?`,
    [title, contents, location, postId, userId],
  );
  return result.affectedRows;
};

exports.deletePost = async (postId, userId) => {
  const [result] = await pool.query(
    `DELETE FROM posts WHERE id = ? AND user_id = ?`,
    [postId, userId],
  );
  return result.affectedRows;
};
