const authModel = require("../models/authModel");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const resend = require("../config/resend");

// 회원가입 (signup)
exports.signup = async (req, res) => {
  try {
    const { username, email, password, repassword, phone } = req.body;

    if (!username || !email || !password || !repassword || !phone) {
      return res.status(400).json({ message: "Required fields are missing." });
    }

    // 1. 이메일 인증 완료 여부 먼저 확인 (테스트를 위해 생략)
    // const isVerified = await authModel.isEmailVerified(email);
    // if (!isVerified) {
    //   return res
    //     .status(400)
    //     .json({ message: "Please verify your email first." });
    // }

    // 2. 이메일 및 전화번호 중복 체크
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
    const { id } = req.params;

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

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "7d" },
    );

    return res.status(200).json({
      message: "Login successful",
      token,
      data: { id: user.id, email: user.email },
    });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// POST /auth/email/send
exports.sendVerificationEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res
        .status(400)
        .json({ success: false, message: "Email is required." });
    }

    // 1. 중복 체크
    const duplicates = await authModel.findByEmailOrPhone(email, "");
    if (duplicates.some((row) => row.email === email)) {
      return res
        .status(409)
        .json({ success: false, message: "This email is already registered." });
    }

    // 2. 6자리 난수 생성
    const code = crypto.randomInt(100000, 999999).toString();

    // 3. Resend 전송
    const { data, error } = await resend.emails.send({
      from: "Auth <onboarding@resend.dev>",
      to: [email],
      subject: "[인증번호] 이메일 인증 코드가 도착했습니다.",
      text: `[서비스명] 이메일 인증 코드는 [${code}] 입니다. (유효시간: 5분)`,
    });

    if (error) {
      console.error("[Resend API Error]", error);
      return res.status(500).json({
        success: false,
        message: "Failed to send email via Resend.",
        error,
      });
    }

    // 4. DB 저장 (formattedExpiresAt 전달 없이 email, code만 전달)
    await authModel.saveVerificationCode(email, code);

    console.log(`[Email Sent Success] Email: ${email} | Code: ${code}`);

    return res.status(200).json({
      success: true,
      message: "Verification code sent successfully.",
      data: { email, resendMessageId: data.id },
    });
  } catch (err) {
    console.error("[Server Error in sendVerificationEmail]", err);
    return res
      .status(500)
      .json({ success: false, message: "An internal server error occurred." });
  }
};

// 이메일 인증 번호 검증
exports.verifyEmailCode = async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) {
      return res.status(400).json({ message: "Email and code are required." });
    }

    const verification = await authModel.findVerificationCode(email, code);

    if (!verification) {
      return res.status(400).json({
        message: "Invalid or expired verification code.",
      });
    }

    // 인증 성공 처리 (is_verified = 1)
    await authModel.markEmailAsVerified(verification.id);

    return res.status(200).json({ message: "Email verification successful." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
