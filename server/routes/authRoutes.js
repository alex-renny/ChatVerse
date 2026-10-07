import express from "express";
import {
  registerUser,
  loginUser,
  getAuthSession,
} from "../controllers/authController.js";
import protect from "../middleware/authMiddleware.js";
import { changeOwnPassword } from "../controllers/passwordController.js";

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/session", protect, getAuthSession);
router.post("/change-password", protect, changeOwnPassword);

export default router;
