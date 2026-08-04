const jwt = require("jsonwebtoken");
const pool = require("../config/db");

exports.verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "No token provided." });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;

    // 마지막 활동 시각이 5분 이상 지났을 때만 갱신
    pool
      .query(
        `UPDATE users SET last_active_at = NOW()
       WHERE id = ? AND (last_active_at IS NULL OR last_active_at < NOW() - INTERVAL 5 MINUTE)`,
        [decoded.id],
      )
      .catch((err) => console.error("last_active_at 갱신 실패:", err));

    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token." });
  }
};
