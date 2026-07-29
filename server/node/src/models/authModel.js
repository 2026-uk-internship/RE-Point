const pool = require("../config/db");

exports.findByUsername = async (username) => {
  const [rows] = await pool.query(
    `SELECT u.id, u.name, a.password
     FROM users u
     JOIN auth a ON u.id = a.user_id
     WHERE u.name = ?`,
    [username],
  );
  return rows[0];
};

// 회원 가입 (signup)
exports.createUser = async (username, email, password, phone) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [auth] = await connection.query(
      `INSERT INTO auth (phone, email, password) VALUES (?, ?, ?)`,
      [phone, email, password],
    );

    const authId = auth.insertId;

    const [location] = await connection.query(
      `INSERT INTO location (country, region, city) VALUES (?, ?, ?)`,
      ["Not Set", "Not Set", "Not Set"],
    );

    const locationId = location.insertId;

    const [user] = await connection.query(
      `INSERT INTO users (id, name, location_id) VALUES (?, ?, ?)`,
      [authId, username, locationId],
    );

    await connection.commit();

    return {
      authId,
      locationId,
      user,
    };
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
};

// 회원 탈퇴
exports.deleteUser = async (id) => {
  const [result] = await pool.query(`DELETE FROM auth WHERE id = ?`, [id]);
  return result;
};
