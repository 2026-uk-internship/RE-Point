const locationModel = require("../models/locationModel");

exports.getLocations = async (req, res) => {
  try {
    const locations = await locationModel.getAllLocations();
    return res.status(200).json({ data: locations });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
