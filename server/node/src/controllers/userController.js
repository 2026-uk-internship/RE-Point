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

exports.updateLocation = async (req, res) => {
  try {
    const { locationId } = req.body;

    if (!locationId) {
      return res.status(400).json({ message: "locationId is required." });
    }

    const affectedRows = await userModel.updateLocation(
      req.user.id,
      locationId,
    );

    if (affectedRows === 0) {
      return res.status(404).json({ message: "User not found." });
    }

    return res.status(200).json({ message: "Location updated successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.updateProfileImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "image file is required." });
    }

    await userModel.updateProfileImage(req.user.id, req.file.path);

    return res.status(200).json({
      message: "Profile image updated successfully.",
      data: { img: req.file.path },
    });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
