import express from "express";
import {sendMessage,getMessages,deleteMessage,} from "../controllers/messageController.js";
import protect from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", protect, sendMessage);
router.get("/:receiverId", protect, getMessages);
router.delete("/:messageId", protect, deleteMessage);

export default router;