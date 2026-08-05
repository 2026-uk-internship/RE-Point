// src/controllers/bidController.js
const bidModel = require("../models/bidModel");

exports.placeBid = async (req, res) => {
  try {
    const { id } = req.params; // productId
    const { point } = req.body;

    if (!point || point <= 0) {
      return res.status(400).json({ message: "Valid point is required." });
    }

    const result = await bidModel.placeBid(req.user.id, id, point);
    return res
      .status(200)
      .json({ message: "Bid placed successfully.", data: result });
  } catch (err) {
    if (err.message === "AUCTION_NOT_FOUND") {
      return res.status(404).json({ message: "Auction not found." });
    }
    if (err.message === "AUCTION_ENDED") {
      return res
        .status(400)
        .json({ message: "This auction has already ended." });
    }
    if (err.message === "BID_TOO_LOW") {
      return res
        .status(400)
        .json({ message: "Bid must be higher than the current highest bid." });
    }
    if (err.message === "INSUFFICIENT_POINT") {
      return res.status(400).json({ message: "Not enough available points." });
    }
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getAuctionParticipants = async (req, res) => {
  try {
    const { id } = req.params; // productId
    const participants = await bidModel.getAuctionParticipants(id);
    return res.status(200).json({ data: participants });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
