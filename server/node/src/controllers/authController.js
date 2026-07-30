const authModel = require("../models/authModel");
const bcrypt = require("bcrypt");

// 회원가입 (signup)
exports.signup = async (req, res) => {
  try {
    const { username, email, password, repassword, phone } = req.body;

    if (!username || !email || !password || !repassword || !phone) {
      return res.status(400).json({ message: "Required fields are missing." });
    }

    const duplicates = await authModel.findByEmailOrPhone(email, phone);

    if (duplicates.length > 0) {
      const emailDup = duplicates.some((row) => row.email === email);
      const phoneDup = duplicates.some((row) => row.phone === phone);

      if (emailDup && phoneDup) {
        return res.status(409).json({
          message: "This email and phone number are already registered.",
        });
      } else if (emailDup) {
        return res
          .status(409)
          .json({ message: "This email is already registered." });
      } else {
        return res
          .status(409)
          .json({ message: "This phone number is already registered." });
      }
    }

    if (password !== repassword) {
      return res.status(400).json({ message: "Passwords do not match." });
    }

    const result = await authModel.createUser(username, email, password, phone);

    return res.status(201).json({
      message: "Signup completed successfully.",
      data: result,
    });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 회원 탈퇴 (delete user)
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params; // 라우트 설계에 따라 req.user.id 등이 될 수도 있음

    const result = await authModel.deleteUser(id);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "User does not exist." });
    }

    return res.status(200).json({ message: "Account deleted successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 로그인 (login)
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "Email and password are required." });
    }

    const user = await authModel.findByUser(email);

    if (!user) {
      return res.status(404).json({ message: "User does not exist." });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Incorrect password." });
    }

    return res
      .status(200)
      .json({ message: "Login successful", data: { email: user.email } });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
