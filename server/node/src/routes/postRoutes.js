// src/routes/postRoutes.js
const express = require("express");
const router = express.Router();
const postController = require("../controllers/postController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.post("/", verifyToken, postController.createPost); // POST /posts
router.get("/", postController.getPostList); // GET /posts?location=
router.get("/:id", postController.getPostDetail); // GET /posts/:id
router.put("/:id", verifyToken, postController.updatePost); // PUT /posts/:id
router.delete("/:id", verifyToken, postController.deletePost); // DELETE /posts/:id
router.post("/:id/comments", verifyToken, postController.createComment); // POST /posts/:id/comments
router.delete(
  "/comments/:commentId",
  verifyToken,
  postController.deleteComment,
); // DELETE /posts/comments/:commentId

module.exports = router;
