import express from "express";
import protect from "../middleware/authMiddleware.js";
import upload from "../config/cloudinaryStorage.js";
import {
  uploadProfilePicture,
  updateProfile,
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

export default router;