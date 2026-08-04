// src/controllers/postController.js
const postModel = require("../models/postModel");
const commentModel = require("../models/commentModel");

exports.createPost = async (req, res) => {
  try {
    const { title, contents, location } = req.body;

    if (!title) {
      return res.status(400).json({ message: "title is required." });
    }

    const postId = await postModel.createPost(req.user.id, {
      title,
      contents,
      location,
    });
    return res
      .status(201)
      .json({ message: "Post created successfully.", data: { id: postId } });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getPostList = async (req, res) => {
  try {
    const { location } = req.query;
    const posts = await postModel.getPostList(location);
    return res.status(200).json({ data: posts });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.getPostDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const post = await postModel.getPostDetail(id);

    if (!post) {
      return res.status(404).json({ message: "Post not found." });
    }

    const comments = await commentModel.getCommentsByPost(id);
    return res.status(200).json({ data: { ...post, comments } });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.updatePost = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, contents, location } = req.body;

    const affectedRows = await postModel.updatePost(id, req.user.id, {
      title,
      contents,
      location,
    });

    if (affectedRows === 0) {
      return res
        .status(404)
        .json({ message: "Post not found or you don't have permission." });
    }

    return res.status(200).json({ message: "Post updated successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.deletePost = async (req, res) => {
  try {
    const { id } = req.params;
    const affectedRows = await postModel.deletePost(id, req.user.id);

    if (affectedRows === 0) {
      return res
        .status(404)
        .json({ message: "Post not found or you don't have permission." });
    }

    return res.status(200).json({ message: "Post deleted successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.createComment = async (req, res) => {
  try {
    const { id } = req.params; // postId
    const { contents } = req.body;

    if (!contents) {
      return res.status(400).json({ message: "contents is required." });
    }

    const commentId = await commentModel.createComment(
      id,
      req.user.id,
      contents,
    );
    return res.status(201).json({
      message: "Comment created successfully.",
      data: { id: commentId },
    });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};

exports.deleteComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const affectedRows = await commentModel.deleteComment(
      commentId,
      req.user.id,
    );

    if (affectedRows === 0) {
      return res
        .status(404)
        .json({ message: "Comment not found or you don't have permission." });
    }

    return res.status(200).json({ message: "Comment deleted successfully." });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ message: "An internal server error occurred." });
  }
};
