import bcrypt from "bcrypt";
import mongoose from "mongoose";
import User from "../models/User.js";
import cloudinary from "../config/cloudinary.js";

const configuredAdminEmail = () =>
  (process.env.ADMIN_EMAIL || "alexmareyamrenny@gmail.com").trim().toLowerCase();

const failedAttempts = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;

const numberOrNull = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
};

export const getAdminOverview = async (req, res) => {
  const requesterId = req.user._id.toString();
  const requesterEmail = (req.user.email || "").trim().toLowerCase();

  if (!requesterEmail || requesterEmail !== configuredAdminEmail()) {
    return res.status(403).json({ message: "Admin access is not enabled for this account" });
  }

  const now = Date.now();
  const attempt = failedAttempts.get(requesterId);
  if (attempt?.lockedUntil > now) {
    return res.status(429).json({ message: "Too many attempts. Try again later." });
  }

  const { password } = req.body;
  if (typeof password !== "string" || password.length === 0) {
    return res.status(400).json({ message: "Enter your account password" });
  }

  const account = await User.findById(requesterId).select("+password email");
  if (!account || account.email.toLowerCase() !== configuredAdminEmail() ||
      !(await bcrypt.compare(password, account.password))) {
    const count = (attempt?.count || 0) + 1;
    failedAttempts.set(requesterId, {
      count: count >= MAX_FAILED_ATTEMPTS ? 0 : count,
      lockedUntil: count >= MAX_FAILED_ATTEMPTS ? now + LOCKOUT_MS : 0,
    });
    return res.status(401).json({ message: "Admin password is incorrect" });
  }
  failedAttempts.delete(requesterId);

  try {
    const database = mongoose.connection.db;
    if (!database) throw new Error("Database connection is not ready");

    const [databaseStats, userCount, users, cloudinaryUsage] = await Promise.all([
      database.stats(),
      User.countDocuments(),
      User.find({}, "name email createdAt")
        .sort({ createdAt: -1 })
        .limit(5000)
        .lean(),
      cloudinary.api.usage().catch((error) => {
        console.error("Cloudinary usage lookup failed:", error.message);
        return null;
      }),
    ]);

    const cloudStorageUsed = numberOrNull(cloudinaryUsage?.storage?.usage);
    const cloudStorageLimit = numberOrNull(cloudinaryUsage?.storage?.limit);
    const atlasUsed = numberOrNull(databaseStats.storageSize) ??
      numberOrNull(databaseStats.dataSize);
    const atlasLimitGb = numberOrNull(process.env.ATLAS_STORAGE_LIMIT_GB);
    const atlasLimitBytes = atlasLimitGb == null ? null : atlasLimitGb * 1024 ** 3;

    return res.json({
      generatedAt: new Date().toISOString(),
      users: {
        count: userCount,
        accounts: users.map(({ _id, name, email, createdAt }) => ({
          id: _id.toString(), name, email, createdAt,
        })),
        listLimit: 5000,
      },
      cloudinary: {
        available: !!cloudinaryUsage,
        storageUsedBytes: cloudStorageUsed,
        storageLimitBytes: cloudStorageLimit,
        storageRemainingBytes: cloudStorageUsed != null && cloudStorageLimit != null
          ? Math.max(0, cloudStorageLimit - cloudStorageUsed)
          : null,
        resources: numberOrNull(cloudinaryUsage?.resources),
        creditsUsed: numberOrNull(cloudinaryUsage?.credits?.usage),
        creditsLimit: numberOrNull(cloudinaryUsage?.credits?.limit),
      },
      atlas: {
        databaseName: database.databaseName,
        storageUsedBytes: atlasUsed,
        dataBytes: numberOrNull(databaseStats.dataSize),
        indexBytes: numberOrNull(databaseStats.indexSize),
        storageLimitBytes: atlasLimitBytes,
        storageRemainingBytes: atlasUsed != null && atlasLimitBytes != null
          ? Math.max(0, atlasLimitBytes - atlasUsed)
          : null,
        collections: numberOrNull(databaseStats.collections),
        documents: numberOrNull(databaseStats.objects),
      },
    });
  } catch (error) {
    console.error("Admin overview failed:", error.message);
    return res.status(503).json({ message: "Could not load admin usage details" });
  }
};
