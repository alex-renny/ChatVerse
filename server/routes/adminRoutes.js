import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  getAdminOverview,
  updatePasswordPolicy,
  changeAdminPassword,
  reviewPasswordChange,
} from "../controllers/adminController.js";

const router = express.Router();

router.post("/overview", protect, getAdminOverview);
router.put("/password-policy", protect, updatePasswordPolicy);
router.put("/password", protect, changeAdminPassword);
router.post("/password-requests/:userId", protect, reviewPasswordChange);

export default router;
