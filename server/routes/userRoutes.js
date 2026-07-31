import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  getUsers,
  getConversationUsers,
  togglePinnedChat,
  saveChatBackground,
  getChatBackground,
  setChatPassword,
  removeChatPassword,
  isChatPasswordEnabled,
  verifyChatPassword,
} from "../controllers/userController.js";

const router = express.Router();

router.get("/conversations", protect, getConversationUsers);
router.get("/", protect, getUsers);
router.put("/:userId/pin", protect, togglePinnedChat);
router.put("/:userId/background", protect, saveChatBackground);
router.get("/:userId/background", protect, getChatBackground);
router.put("/chat-password",protect,setChatPassword);
router.delete("/chat-password",protect,removeChatPassword);
router.get("/:userId/chat-password-enabled",protect,isChatPasswordEnabled);
router.post("/verify-chat-password",protect,verifyChatPassword);

export default router;