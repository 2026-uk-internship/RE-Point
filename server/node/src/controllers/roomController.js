exports.enterRoom = async (req, res) => {
  try {
    const { productId, sellerId } = req.body;
    const buyerId = req.user.id;

    const roomId = await roomModel.findOrCreateRoom(
      productId,
      buyerId,
      sellerId,
    );

    return res.status(200).json({ data: { roomId } });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
