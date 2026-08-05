// src/routes/productRoutes.js
const bidController = require("../controllers/bidController"); // 상단 import 추가
router.post("/:id/bid", verifyToken, bidController.placeBid); // POST /products/:id/bid
