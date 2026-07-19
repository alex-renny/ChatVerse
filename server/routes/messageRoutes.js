import express from "express";
import {sendMessage,getMessages,deleteMessage,markAsSeen,reactToMessage,togglePinMessage,unpinMessage} from "../controllers/messageController.js";
import protect from "../middleware/authMiddleware.js";
import upload from "../config/multer.js";

const router = express.Router();

router.post("/",protect,upload.single("attachment"),sendMessage);
router.get("/:receiverId", protect, getMessages);
router.delete("/:messageId", protect, deleteMessage);
router.put("/seen/:senderId", protect, markAsSeen);
router.put("/react/:messageId",protect,reactToMessage);
router.put("/pin/:messageId", protect, togglePinMessage);
router.put("/unpin/:messageId", protect, unpinMessage);

export default router;
