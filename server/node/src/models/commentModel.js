// src/models/commentModel.js
const pool = require("../config/db");

exports.createComment = async (postId, userId, contents) => {
  const [result] = await pool.query(
    `INSERT INTO comments (contents, user_id, post_id) VALUES (?, ?, ?)`,
    [contents, userId, postId],
  );
  return result.insertId;
};

exports.getCommentsByPost = async (postId) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.contents, u.name AS userName
     FROM comments c
     LEFT JOIN users u ON u.id = c.user_id
     WHERE c.post_id = ?
     ORDER BY c.id ASC`,
    [postId],
  );
  return rows;
};

exports.deleteComment = async (commentId, userId) => {
  const [result] = await pool.query(
    `DELETE FROM comments WHERE id = ? AND user_id = ?`,
    [commentId, userId],
  );
  return result.affectedRows;
};
