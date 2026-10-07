import express from "express";
import protect from "../middleware/authMiddleware.js";
import {
  getAdminOverview,
  updatePasswordPolicy,
  changeAdminPassword,
  reviewPasswordChange,
  sendAdminMessage,
  removeUserAccount,
} from "../controllers/adminController.js";

const router = express.Router();

router.post("/overview", protect, getAdminOverview);
router.put("/password-policy", protect, updatePasswordPolicy);
router.put("/password", protect, changeAdminPassword);
router.post("/password-requests/:userId", protect, reviewPasswordChange);
router.post("/users/:userId/messages", protect, sendAdminMessage);
router.post("/users/:userId/remove", protect, removeUserAccount);

export default router;
