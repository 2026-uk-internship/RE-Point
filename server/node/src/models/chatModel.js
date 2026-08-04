const pool = require("../config/db");
const { formatTimeAMPM } = require("../utils/formatTime");

exports.getMessagesByRoom = async (roomId) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.user_id, u.name AS user_name, c.message, c.date
     FROM chats c
     JOIN users u ON u.id = c.user_id
     WHERE c.room_id = ?
     ORDER BY c.date ASC`,
    [roomId],
  );

  return rows.map((row) => ({
    ...row,
    timeDisplay: formatTimeAMPM(row.date), // "09:41 AM"
  }));
};

exports.saveMessage = async ({ roomId, userId, message }) => {
  const [result] = await pool.query(
    `INSERT INTO chats (room_id, user_id, message) VALUES (?, ?, ?)`,
    [roomId, userId, message],
  );
  return result.insertId;
};
