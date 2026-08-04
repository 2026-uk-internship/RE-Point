const favoriteModel = require("../models/favoriteModel");

exports.toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params; // productId
    const result = await favoriteModel.toggleFavorite(req.user.id, id);
    return res.status(200).json({ data: result });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
