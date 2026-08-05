const categoryModel = require("../models/categoryModel");

// 전체 카테고리 목록
exports.getCategories = async (req, res) => {
  try {
    const categories = await categoryModel.getAllCategories();
    return res.status(200).json({ data: categories });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 사용자가 선택한 카테고리 조회
exports.getUserCategories = async (req, res) => {
  try {
    const { id } = req.params;
    const categories = await categoryModel.getUserCategories(id);
    return res.status(200).json({ data: categories });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

// 사용자 카테고리 저장 (최대 5개)
exports.setUserCategories = async (req, res) => {
  try {
    const { id } = req.params;
    const { categoryIds } = req.body; // 예: [1, 3, 5]

    if (!Array.isArray(categoryIds)) {
      return res.status(400).json({ message: "categoryIds must be an array." });
    }

    const uniqueIds = [...new Set(categoryIds)];

    if (uniqueIds.length > 5) {
      return res
        .status(400)
        .json({ message: "You can select up to 5 categories." });
    }

    await categoryModel.setUserCategories(id, uniqueIds);

    return res
      .status(200)
      .json({ message: "Categories updated successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getGroups = async (req, res) => {
  try {
    const groups = await categoryModel.getAllGroups();
    return res.status(200).json({ data: groups });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getGroupCategories = async (req, res) => {
  try {
    const { id } = req.params;
    const categories = await categoryModel.getCategoriesByGroup(id);
    return res.status(200).json({ data: categories });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
