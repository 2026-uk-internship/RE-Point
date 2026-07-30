const pool = require("../config/db");

const bcrypt = require("bcrypt");
const SALT_ROUNDS = 10;

// 회원 가입 (signup)
exports.createUser = async (username, email, password, phone) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

    const [auth] = await connection.query(
      `INSERT INTO auth (phone, email, password) VALUES (?, ?, ?)`,
      [phone, email, hashedPassword],
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

    return { authId, locationId, user };
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

// 로그인 (login)
exports.findByUser = async (email) => {
  const [rows] = await pool.query(
    `SELECT email, password FROM auth WHERE email = ?`,
    [email],
  );
  return rows[0]; // result or undefined
};

// email and phone check
exports.findByEmailOrPhone = async (email, phone) => {
  const [rows] = await pool.query(
    `SELECT email, phone FROM auth WHERE email = ? OR phone = ?`,
    [email, phone],
  );
  return rows; // 배열 그대로 반환 (0개, 1개, 혹은 이론상 2개)
};
