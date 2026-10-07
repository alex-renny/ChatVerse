import bcrypt from "bcrypt";
import mongoose from "mongoose";
import User from "../models/User.js";
import AppSettings from "../models/AppSettings.js";
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

const verifyAdminPassword = async (req, password, res) => {
  const requesterId = req.user._id.toString();
  const requesterEmail = (req.user.email || "").trim().toLowerCase();
  if (!requesterEmail || requesterEmail !== configuredAdminEmail()) {
    res.status(403).json({ message: "Admin access is not enabled for this account" });
    return null;
  }

  const now = Date.now();
  const attempt = failedAttempts.get(requesterId);
  if (attempt?.lockedUntil > now) {
    res.status(429).json({ message: "Too many attempts. Try again later." });
    return null;
  }
  if (typeof password !== "string" || password.length === 0) {
    res.status(400).json({ message: "Enter your account password" });
    return null;
  }

  const account = await User.findById(requesterId).select("+password email");
  if (!account || account.email.toLowerCase() !== configuredAdminEmail() ||
      !(await bcrypt.compare(password, account.password))) {
    const count = (attempt?.count || 0) + 1;
    failedAttempts.set(requesterId, {
      count: count >= MAX_FAILED_ATTEMPTS ? 0 : count,
      lockedUntil: count >= MAX_FAILED_ATTEMPTS ? now + LOCKOUT_MS : 0,
    });
    res.status(401).json({ message: "Admin password is incorrect" });
    return null;
  }
  failedAttempts.delete(requesterId);
  return account;
};

export const getAdminOverview = async (req, res) => {
  if (!(await verifyAdminPassword(req, req.body?.password, res))) return;

  try {
    const database = mongoose.connection.db;
    if (!database) throw new Error("Database connection is not ready");

    const [databaseStats, userCount, users, cloudinaryUsage, settings, pendingRequests] = await Promise.all([
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
      AppSettings.findOne({ key: "global" }).lean(),
      User.find({ pendingPasswordChangeHash: { $exists: true, $ne: "" } },
        "name email passwordChangeRequestedAt")
        .sort({ passwordChangeRequestedAt: 1 })
        .lean(),
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
      passwordPolicy: {
        allowUserPasswordChange: settings?.allowUserPasswordChange === true,
        pendingRequests,
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

export const updatePasswordPolicy = async (req, res) => {
  if (!(await verifyAdminPassword(req, req.body?.password, res))) return;
  if (typeof req.body.allowUserPasswordChange !== "boolean") {
    return res.status(400).json({ message: "Choose whether users may change passwords" });
  }
  const settings = await AppSettings.findOneAndUpdate(
    { key: "global" },
    { $set: { allowUserPasswordChange: req.body.allowUserPasswordChange } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  ).lean();
  return res.json({ allowUserPasswordChange: settings.allowUserPasswordChange });
};

export const changeAdminPassword = async (req, res) => {
  const account = await verifyAdminPassword(req, req.body?.currentPassword, res);
  if (!account) return;
  const { newPassword } = req.body;
  if (typeof newPassword !== "string" || newPassword.length < 6) {
    return res.status(400).json({ message: "New password must be at least 6 characters" });
  }
  if (await bcrypt.compare(newPassword, account.password)) {
    return res.status(400).json({ message: "Choose a password different from your current password" });
  }
  account.password = await bcrypt.hash(newPassword, 10);
  await account.save();
  return res.json({ success: true, message: "Admin password changed successfully" });
};

export const reviewPasswordChange = async (req, res) => {
  if (!(await verifyAdminPassword(req, req.body?.password, res))) return;
  const userId = req.params.userId;
  const { approve } = req.body;
  if (typeof userId !== "string" || typeof approve !== "boolean") {
    return res.status(400).json({ message: "Invalid password request" });
  }
  const user = await User.findById(userId).select("+pendingPasswordChangeHash passwordChangeCount");
  if (!user?.pendingPasswordChangeHash) {
    return res.status(404).json({ message: "Password request no longer exists" });
  }
  if (approve) {
    user.password = user.pendingPasswordChangeHash;
    user.passwordChangeCount = (user.passwordChangeCount || 0) + 1;
  }
  user.pendingPasswordChangeHash = "";
  user.passwordChangeRequestedAt = null;
  await user.save();
  return res.json({ success: true, message: approve ? "Password request approved" : "Password request denied" });
};
