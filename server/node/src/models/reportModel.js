const pool = require("../config/db");

exports.createReport = async ({ user_id, type, contents, related_id }) => {
  const [result] = await pool.query(
    `INSERT INTO reports (user_id, type, contents, related_id)
         VALUES (?, ?, ?, ?)`,
    [user_id, type, contents, related_id],
  );

  return result.insertId;
};
