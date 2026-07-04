import express from "express";
import {sendMessage,getMessages,deleteMessage,markAsSeen,} from "../controllers/messageController.js";
import protect from "../middleware/authMiddleware.js";
import upload from "../config/multer.js";

const router = express.Router();

router.post("/",protect,upload.single("image"),sendMessage);
router.get("/:receiverId", protect, getMessages);
router.delete("/:messageId", protect, deleteMessage);
router.put("/seen/:senderId", protect, markAsSeen);

export default router;