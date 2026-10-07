import express from "express";
import {
  registerUser,
  loginUser,
  getAuthSession,
} from "../controllers/authController.js";
import protect from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/session", protect, getAuthSession);

export default router;
