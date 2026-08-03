const roomModel = require("../models/roomModel");

exports.enterRoom = async (req, res) => {
  try {
    const { productId } = req.body;
    const buyerId = req.user.id;

    if (!productId) {
      return res.status(400).json({ message: "productId is required." });
    }

    const roomId = await roomModel.findOrCreateRoom(productId, buyerId);

    return res.status(200).json({ data: { roomId } });
  } catch (err) {
    if (err.message === "PRODUCT_NOT_FOUND") {
      return res.status(404).json({ message: "Product not found." });
    }
    if (err.message === "CANNOT_CHAT_WITH_SELF") {
      return res
        .status(400)
        .json({ message: "You cannot chat with yourself." });
    }
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getRoomList = async (req, res) => {
  try {
    const rooms = await roomModel.getRoomList(req.user.id);
    return res.status(200).json({ data: rooms });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
