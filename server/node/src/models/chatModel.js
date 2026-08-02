const pool = require("../config/db");

exports.getMessagesByRoom = async (roomId) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.user_id, u.name AS user_name, c.message, c.date
     FROM chats c
     JOIN users u ON u.id = c.user_id
     WHERE c.room_id = ?
     ORDER BY c.date ASC`,
    [roomId],
  );
  return rows;
};

exports.saveMessage = async ({ roomId, userId, message }) => {
  const [result] = await pool.query(
    `INSERT INTO chats (room_id, user_id, message) VALUES (?, ?, ?)`,
    [roomId, userId, message],
  );
  return result.insertId;
};
