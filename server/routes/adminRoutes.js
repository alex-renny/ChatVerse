import express from "express";
import protect from "../middleware/authMiddleware.js";
import { getAdminOverview } from "../controllers/adminController.js";

const router = express.Router();

router.post("/overview", protect, getAdminOverview);

export default router;
