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
      `INSERT INTO auth (phone, email, password, is_verified) VALUES (?, ?, ?, ?)`,
      [phone, email, hashedPassword, true],
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
    `SELECT id, email, password FROM auth WHERE email = ?`,
    [email],
  );
  return rows[0];
};

// email and phone check
exports.findByEmailOrPhone = async (email, phone) => {
  const [rows] = await pool.query(
    `SELECT email, phone FROM auth WHERE email = ? OR phone = ?`,
    [email, phone],
  );
  return rows; // 배열 그대로 반환 (0개, 1개, 혹은 이론상 2개)
};

// Email Verification
// 1. 인증 코드 저장 (기존 코드가 있다면 덮어쓰거나 새로 추가)
exports.saveVerificationCode = async (email, code) => {
  const [result] = await pool.query(
    `INSERT INTO email_verifications (email, code, expires_at) 
     VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))`,
    [email, code],
  );
  return result;
};

// 2. 인증 코드 검증 조회
exports.findVerificationCode = async (email, code) => {
  const [rows] = await pool.query(
    `SELECT * FROM email_verifications 
     WHERE email = ? AND code = ? AND is_verified = 0 AND expires_at > NOW()
     ORDER BY id DESC LIMIT 1`,
    [email, code],
  );
  return rows[0];
};

// 3. 인증 완료 상태로 변경
exports.markEmailAsVerified = async (verificationId) => {
  await pool.query(
    `UPDATE email_verifications SET is_verified = 1 WHERE id = ?`,
    [verificationId],
  );
};

// 4. 이메일 인증이 완료되었는지 확인 (회원가입 전 검증용)
exports.isEmailVerified = async (email) => {
  const [rows] = await pool.query(
    `SELECT id FROM email_verifications 
     WHERE email = ? AND is_verified = 1 
     ORDER BY id DESC LIMIT 1`,
    [email],
  );
  return rows.length > 0;
};
