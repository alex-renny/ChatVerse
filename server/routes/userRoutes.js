import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  getUsers,
  getConversationUsers,
  togglePinnedChat,
  saveChatBackground,
  getChatBackground,
} from "../controllers/userController.js";

const router = express.Router();

router.get("/conversations", protect, getConversationUsers);

router.get("/", protect, getUsers);

router.put("/:userId/pin", protect, togglePinnedChat);

router.put("/:userId/background", protect, saveChatBackground);

router.get("/:userId/background", protect, getChatBackground);

export default router;