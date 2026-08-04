const userModel = require("../models/userModel");

exports.getMyProfile = async (req, res) => {
  try {
    const profile = await userModel.getProfile(req.user.id);

    if (!profile) {
      return res.status(404).json({ message: "User not found." });
    }

    return res.status(200).json({ data: profile });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
