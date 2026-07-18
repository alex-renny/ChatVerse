import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  getUsers,
  getConversationUsers,
  togglePinnedChat,
} from "../controllers/userController.js";

const router = express.Router();
router.get(
  "/conversations",
  protect,
  getConversationUsers
);   
router.get("/", protect, getUsers);
router.put("/:userId/pin", protect, togglePinnedChat);

export default router;
