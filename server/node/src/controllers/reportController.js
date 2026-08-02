const reportModel = require("../models/reportModel");

exports.createReport = async (req, res) => {
  try {
    const { type, contents, related_id } = req.body;

    const VALID_TYPES = ["user", "chat", "product", "review"];

    if (!VALID_TYPES.includes(type)) {
      return res.status(400).json({ message: "Invalid report type." });
    }

    if (!type || !contents || !related_id) {
      return res.status(400).json({ message: "Required fields are missing." });
    }
    const reportId = await reportModel.createReport({
      user_id: req.user.id,
      type,
      contents,
      related_id,
    });

    return res.status(201).json({
      message: "Report submitted successfully.",
      reportId,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      message: "An internal server error occurred.",
    });
  }
};
