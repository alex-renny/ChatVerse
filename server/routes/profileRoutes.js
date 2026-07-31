import express from "express";
import protect from "../middleware/authMiddleware.js";
import upload from "../config/cloudinaryStorage.js";
import {
  uploadProfilePicture,
  updateProfile,
  setChatPassword,
  removeChatPassword,
  getChatPasswordStatus,
  removeVerifiedUser,
} from "../controllers/profileController.js";

const router = express.Router();

router.put(
  "/picture",
  protect,
  upload.single("profile"),
  uploadProfilePicture
);

router.put(
  "/update",
  protect,
  updateProfile
);
router.put(
  "/chat-password",
  protect,
  setChatPassword
);

router.delete(
  "/chat-password",
  protect,
  removeChatPassword
);

router.get(
  "/chat-password",
  protect,
  getChatPasswordStatus
);

router.delete(
  "/chat-password/access/:userId",
  protect,
  removeVerifiedUser
);

export default router;