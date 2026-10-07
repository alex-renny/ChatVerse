import bcrypt from "bcrypt";
import mongoose from "mongoose";
import User from "../models/User.js";
import AppSettings from "../models/AppSettings.js";
import Message from "../models/Message.js";
import cloudinary from "../config/cloudinary.js";
import { io, onlineUsers } from "../server.js";

const configuredAdminEmail = () =>
  (process.env.ADMIN_EMAIL || "alexmareyamrenny@gmail.com").trim().toLowerCase();

const failedAttempts = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;

const numberOrNull = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
};

const cloudinaryAssetsForMessage = (message) => {
  const assets = [];
  const add = (publicId, resourceType) => {
    if (publicId && resourceType) assets.push({ publicId, resourceType });
  };
  add(message.imagePublicId, message.imageResourceType || "image");
  const attachment = message.attachment || {};
  if (attachment.cloudinaryPublicId) {
    add(attachment.cloudinaryPublicId, attachment.resourceType || "raw");
  }

  // Older records may only contain a Cloudinary delivery URL.
  for (const url of [message.image, attachment.url]) {
    if (!url || assets.length) continue;
    const match = url.match(/\/(image|video|raw)\/upload\/(?:v\d+\/)?(.+?)(?:\?.*)?$/);
    if (!match) continue;
    const [, resourceType, path] = match;
    add(resourceType === "image" || resourceType === "video"
      ? path.replace(/\.[^.\/]+$/, "")
      : path, resourceType);
  }
  return [...new Map(assets.map((asset) => [`${asset.resourceType}:${asset.publicId}`, asset])).values()];
};

const deleteMessageAssets = async (messages) => {
  let failed = false;
  for (let index = 0; index < messages.length; index += 5) {
    const batch = messages.slice(index, index + 5);
    await Promise.all(batch.flatMap((message) =>
      cloudinaryAssetsForMessage(message).map(async (asset) => {
        try {
          const result = await cloudinary.uploader.destroy(asset.publicId, {
            resource_type: asset.resourceType,
            invalidate: true,
          });
          if (result.result !== "ok" && result.result !== "not found") {
            failed = true;
            console.error("Cloudinary did not confirm asset removal:", result.result);
          }
        } catch (error) {
          failed = true;
          console.error("Cloudinary cleanup failed during account removal:", error.message);
        }
      })
    ));
  }
  return failed;
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

  let account;
  try {
    // Explicit inclusion is required because this query follows a protected
    // request whose user document was loaded with `-password`.
    account = await User.findById(requesterId).select("email password");
  } catch (error) {
    console.error("Admin account lookup failed:", error.message);
    res.status(503).json({ message: "Unable to verify the admin account right now" });
    return null;
  }
  if (!account || !account.password) {
    console.error("Admin account password hash was not returned by MongoDB");
    res.status(503).json({ message: "Unable to verify the admin account right now" });
    return null;
  }
  if (account.email.toLowerCase() !== configuredAdminEmail() ||
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
          isAdmin: email?.trim().toLowerCase() === configuredAdminEmail(),
        })),
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
  const user = await User.findById(userId).select("password passwordChangeCount +pendingPasswordChangeHash");
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

export const sendAdminMessage = async (req, res) => {
  const account = await verifyAdminPassword(req, req.body?.password, res);
  if (!account) return;

  const { userId } = req.params;
  const text = typeof req.body?.text === "string" ? req.body.text.trim() : "";
  if (!mongoose.isValidObjectId(userId) || !text || text.length > 2000) {
    return res.status(400).json({ message: "Choose a user and enter a message up to 2,000 characters" });
  }
  if (userId === account._id.toString()) {
    return res.status(400).json({ message: "Choose another account to message" });
  }

  const recipient = await User.findById(userId).select("_id");
  if (!recipient) return res.status(404).json({ message: "User not found" });

  const message = await Message.create({
    sender: account._id,
    receiver: recipient._id,
    text,
  });
  const socketId = onlineUsers.get(recipient._id.toString());
  if (socketId) {
    message.delivered = true;
    await message.save();
    io.to(socketId).emit("receiveMessage", message);
  }
  return res.status(201).json({
    success: true,
    delivered: message.delivered,
    message: "Admin message sent from your account",
  });
};

export const removeUserAccount = async (req, res) => {
  const account = await verifyAdminPassword(req, req.body?.password, res);
  if (!account) return;

  const { userId } = req.params;
  if (!mongoose.isValidObjectId(userId) || userId === account._id.toString()) {
    return res.status(400).json({ message: "This account cannot be removed" });
  }

  const target = await User.findById(userId).select("name email profilePic profilePicPublicId");
  if (!target) return res.status(404).json({ message: "User not found" });
  if (target.email.toLowerCase() === configuredAdminEmail()) {
    return res.status(403).json({ message: "The admin account cannot be removed here" });
  }
  if (typeof req.body.confirmEmail !== "string" ||
      req.body.confirmEmail.trim().toLowerCase() !== target.email.toLowerCase()) {
    return res.status(400).json({ message: "The confirmation email does not match this account" });
  }

  const criteria = { $or: [{ sender: target._id }, { receiver: target._id }] };
  const messages = await Message.find(criteria)
    .select("_id sender receiver image imagePublicId imageResourceType attachment replyTo").lean();
  const messageIds = messages.map((message) => message._id);

  // Remove uploaded media associated with the account's messages. Failures are
  // logged while account removal continues, so an external media outage cannot
  // leave the account active after the admin confirmed removal.
  const mediaCleanupFailed = await deleteMessageAssets([
    ...messages,
    {
      image: target.profilePic,
      imagePublicId: target.profilePicPublicId,
      imageResourceType: "image",
    },
  ]);

  if (messageIds.length) {
    await Message.updateMany({ replyTo: { $in: messageIds } }, { $unset: { replyTo: 1 } });
    await Message.deleteMany({ _id: { $in: messageIds } });
  }
  await Message.updateMany({ "reactions.user": target._id }, { $pull: { reactions: { user: target._id } } });
  await Message.updateMany({ deletedFor: target._id }, { $pull: { deletedFor: target._id } });
  await Message.updateMany({ pinnedBy: target._id }, {
    $set: { pinned: false },
    $unset: { pinnedBy: 1, pinnedAt: 1 },
  });
  await User.updateMany({ _id: { $ne: target._id } }, {
    $pull: { pinnedChats: target._id, verifiedUsers: target._id },
    $unset: { [`chatBackgrounds.${target._id}`]: 1 },
  });
  await User.deleteOne({ _id: target._id });

  const targetSocketId = onlineUsers.get(target._id.toString());
  if (targetSocketId) {
    io.sockets.sockets.get(targetSocketId)?.disconnect(true);
    onlineUsers.delete(target._id.toString());
    io.emit("onlineUsers", [...onlineUsers.keys()]);
  }

  const notifiedSockets = new Set();
  for (const message of messages) {
    for (const participantId of [message.sender.toString(), message.receiver.toString()]) {
      const socketId = onlineUsers.get(participantId);
      if (socketId && !notifiedSockets.has(`${socketId}:${message._id}`)) {
        io.to(socketId).emit("messageDeleted", { messageId: message._id.toString() });
        notifiedSockets.add(`${socketId}:${message._id}`);
      }
    }
  }

  return res.json({
    success: true,
    removedMessageCount: messageIds.length,
    mediaCleanupFailed,
  });
};
