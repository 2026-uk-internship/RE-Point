const searchModel = require("../models/searchModel");
const productModel = require("../models/productModel");

exports.getRecentSearches = async (req, res) => {
  try {
    const searches = await searchModel.getRecentSearches(req.user.id);
    return res.status(200).json({ data: searches });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.deleteRecentSearch = async (req, res) => {
  try {
    const { searchId } = req.params;
    const affectedRows = await searchModel.deleteRecentSearch(
      req.user.id,
      searchId,
    );

    if (affectedRows === 0) {
      return res.status(404).json({ message: "Search history not found." });
    }

    return res
      .status(200)
      .json({ message: "Search history deleted successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.searchProducts = async (req, res) => {
  try {
    const { keyword } = req.query;

    if (!keyword) {
      return res.status(400).json({ message: "keyword is required." });
    }

    await searchModel.logSearch(req.user.id, keyword);

    const products = await productModel.searchProducts(keyword);
    return res.status(200).json({ data: products });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getPopularSearches = async (req, res) => {
  try {
    const popular = await searchModel.getPopularSearchesThisMonth();
    return res.status(200).json({ data: popular });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
