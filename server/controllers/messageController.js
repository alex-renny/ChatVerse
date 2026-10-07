import Message from "../models/Message.js";
import User from "../models/User.js";
import { io, onlineUsers } from "../server.js";
import cloudinary from "../config/cloudinary.js";

const canAccessChat = (owner, requesterId) => {
  if (!owner.chatPasswordEnabled) return true;

  return owner.verifiedUsers.some(
    (id) => id.toString() === requesterId.toString()
  );
};

const requesterCanAccessMessage = async (message, requesterId) => {
  const senderId = message.sender.toString();
  const receiverId = message.receiver.toString();
  if (senderId !== requesterId.toString() && receiverId !== requesterId.toString()) return false;
  const otherId = senderId === requesterId.toString() ? receiverId : senderId;
  const otherUser = await User.findById(otherId).select("chatPasswordEnabled verifiedUsers");
  return !!otherUser && canAccessChat(otherUser, requesterId);
};

const getCloudinaryAsset = (message) => {
  const storedPublicId = message.imagePublicId || message.attachment?.cloudinaryPublicId;

  if (storedPublicId) {
    const mime = message.attachment?.mimeType || "";
    const defaultType = message.image
      ? message.imageResourceType || "image"
      : message.attachment?.resourceType ||
        (mime.startsWith("video/") || mime.startsWith("audio/") ? "video" : "raw");

    return { publicId: storedPublicId, resourceType: defaultType };
  }

  // Messages created before Cloudinary IDs were saved can still be cleaned up
  // when their URL is a standard Cloudinary delivery URL.
  const url = message.image || message.attachment?.url;
  const match = url?.match(/\/(image|video|raw)\/upload\/(?:v\d+\/)?(.+?)(?:\?.*)?$/);

  if (!match) return null;

  const [, resourceType, path] = match;
  const publicId = resourceType === "raw" ? path : path.replace(/\.[^.\/]+$/, "");

  return { publicId, resourceType };
};

const deleteCloudinaryAsset = async (message) => {
  const asset = getCloudinaryAsset(message);

  if (!asset) return;

  const typesToTry = [asset.resourceType];
  const mime = message.attachment?.mimeType || "";
  if (mime.startsWith("audio/") && !typesToTry.includes("video")) {
    typesToTry.push("video");
  }
  if (!typesToTry.includes("raw")) {
    typesToTry.push("raw");
  }

  for (const resourceType of typesToTry) {
    try {
      const result = await cloudinary.uploader.destroy(asset.publicId, {
        resource_type: resourceType,
        invalidate: true,
      });

      if (result.result === "ok" || result.result === "not found") return;

      console.warn("Cloudinary did not confirm asset deletion:", result);
    } catch (error) {
      console.error(`Failed to delete Cloudinary asset as ${resourceType}:`, error);
    }
  }
};

// Send a message
export const sendMessage = async (req, res) => {
  try {
    const { receiver, text, replyTo } = req.body;

    const receiverUser = await User.findById(receiver);

    if (!receiverUser) {
      return res.status(404).json({
        message: "Receiver not found",
      });
    }

    if (!canAccessChat(receiverUser, req.user._id)) {
      return res.status(403).json({
        message: "Chat password required",
      });
    }

    const uploadUrl = req.file ? req.file.path : "";
    const isImage = req.file?.mimetype?.startsWith("image/");
    const isVoice = req.body.isVoice === "true";
    const image = isImage ? uploadUrl : "";
    const mime = req.file?.mimetype || "";
    const attachment = req.file && !image
      ? {
          url: uploadUrl,
          name: isVoice ? "Voice message" : req.file.originalname,
          mimeType: req.file.mimetype,
          size: req.file.size,
          cloudinaryPublicId: req.file.filename,
          resourceType: mime.startsWith("video/") || mime.startsWith("audio/") ? "video" : "raw",
          isVoice,
        }
      : undefined;

    const messageData = {
  sender: req.user._id,
  receiver,
  text,
  image,
  imagePublicId: isImage ? req.file.filename : "",
  imageResourceType: isImage ? "image" : "",
};

if (attachment) {
  messageData.attachment = attachment;
}

if (replyTo) {
  messageData.replyTo = replyTo;
}

const message = await Message.create(messageData);

// Populate replyTo before sending to clients
await message.populate("replyTo");

const receiverSocketId = onlineUsers.get(receiver);

if (receiverSocketId) {
  message.delivered = true;
  await message.save();
  io.to(receiverSocketId).emit("receiveMessage", message);
}

res.status(201).json(message);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

// Get conversation
export const getMessages = async (req, res) => {
  try {
    const { receiverId } = req.params;

    const chatPartner = await User.findById(receiverId);

    if (!chatPartner) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    if (!canAccessChat(chatPartner, req.user._id)) {
      return res.status(403).json({
        message: "Chat password required",
      });
    }

    const limit = Math.max(Number(req.query.limit) || 30, 1);
    const skip = Math.max(Number(req.query.skip) || 0, 0);

    const query = {
      $or: [
        {
          sender: req.user._id,
          receiver: receiverId,
        },
        {
          sender: receiverId,
          receiver: req.user._id,
        },
      ],

      deletedFor: {
        $ne: req.user._id,
      },

      deletedForEveryone: {
        $ne: true,
      },
    };

    const messages = await Message.find(query)
      .populate("replyTo")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const pinnedMessage = await Message.findOne({
      ...query,
      pinned: true,
    }).populate("replyTo");

    res.json({
      messages,
      pinnedMessage,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const markAsSeen = async (req, res) => {
  try {
    const { senderId } = req.params;

    if (senderId === req.user._id.toString()) {
      return res.status(400).json({ message: "Invalid sender" });
    }
    const sender = await User.findById(senderId).select("_id chatPasswordEnabled verifiedUsers");
    if (!sender) return res.status(404).json({ message: "User not found" });
    if (!canAccessChat(sender, req.user._id)) {
      return res.status(403).json({ message: "Chat password required" });
    }

    await Message.updateMany(
      {
        sender: senderId,
        receiver: req.user._id,
        seen: false,
      },
      {
        seen: true,
      }
    );

    res.json({
      message: "Messages marked as seen",
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

// Delete a message (Delete for Me)
export const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { deleteForEveryone } = req.body;

    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({
        message: "Message not found",
      });
    }

    if (!(await requesterCanAccessMessage(message, req.user._id))) {
      return res.status(403).json({ message: "Chat password required" });
    }

    // Delete for Everyone
    if (deleteForEveryone) {

      // Only sender can delete for everyone
      if (message.sender.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          message: "Only sender can delete for everyone",
        });
      }

      await deleteCloudinaryAsset(message);

      await message.deleteOne();

      const deletedMessage = { messageId: message._id.toString() };
      const senderSocket = onlineUsers.get(message.sender.toString());
      const receiverSocket = onlineUsers.get(message.receiver.toString());

      if (senderSocket) {
        io.to(senderSocket).emit("messageDeleted", deletedMessage);
      }

      if (receiverSocket) {
        io.to(receiverSocket).emit("messageDeleted", deletedMessage);
      }

        return res.json({
          message: "Deleted for everyone",
        });
    }

    const userId = req.user._id.toString();

    // Only sender or receiver can delete for themselves
    if (
      message.sender.toString() !== userId &&
      message.receiver.toString() !== userId
    ) {
      return res.status(403).json({
        message: "Not authorized",
      });
    }

    // Add current user to deletedFor
    if (!message.deletedFor.includes(userId)) {
      message.deletedFor.push(userId);
    }

    // If both users deleted it, remove permanently
    if (
      message.deletedFor.includes(message.sender.toString()) &&
      message.deletedFor.includes(message.receiver.toString())
    ) {
      await deleteCloudinaryAsset(message);
      await message.deleteOne();

      const deletedMessage = { messageId: message._id.toString() };
      const senderSocket = onlineUsers.get(message.sender.toString());
      const receiverSocket = onlineUsers.get(message.receiver.toString());

      if (senderSocket) io.to(senderSocket).emit("messageDeleted", deletedMessage);
      if (receiverSocket) io.to(receiverSocket).emit("messageDeleted", deletedMessage);
    } else {
      await message.save();
    }

    res.json({
      message: "Deleted for you",
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const reactToMessage = async (req, res) => {
  try {
    const { emoji } = req.body;
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({
        message: "Message not found",
      });
    }

    if (!(await requesterCanAccessMessage(message, req.user._id))) {
      return res.status(403).json({ message: "Chat password required" });
    }

    const existingReaction = message.reactions.find(
      (reaction) => reaction.user.toString() === userId
    );

    if (existingReaction) {
      if (existingReaction.emoji === emoji) {
        // Remove reaction if same emoji clicked
        message.reactions = message.reactions.filter(
          (reaction) => reaction.user.toString() !== userId
        );
      } else {
        // Change reaction
        existingReaction.emoji = emoji;
      }
    } else {
      // Add new reaction
      message.reactions.push({
        user: userId,
        emoji,
      });
    }

    await message.save();

    const receiverSocket = onlineUsers.get(message.receiver.toString());
    const senderSocket = onlineUsers.get(message.sender.toString());

    if (receiverSocket) io.to(receiverSocket).emit("messageReaction", message);
    if (senderSocket) io.to(senderSocket).emit("messageReaction", message);

    res.json(message);
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to react to message",
    });
  }
};

export const togglePinMessage = async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({
        message: "Message not found",
      });
    }

    if (!(await requesterCanAccessMessage(message, req.user._id))) {
      return res.status(403).json({ message: "Chat password required" });
    }

    // Remove previous pin in this conversation
    const previouslyPinned = await Message.find({
      $or: [
        {
          sender: message.sender,
          receiver: message.receiver,
        },
        {
          sender: message.receiver,
          receiver: message.sender,
        },
      ],
      pinned: true,
    });

    for (const msg of previouslyPinned) {
      msg.pinned = false;
      msg.pinnedBy = null;
      msg.pinnedAt = null;
      await msg.save();

      const populated = await Message.findById(msg._id).populate("replyTo");

      const senderSocket = onlineUsers.get(msg.sender.toString());
      const receiverSocket = onlineUsers.get(msg.receiver.toString());

      if (senderSocket) {
        io.to(senderSocket).emit("messageUpdated", populated);
      }

      if (receiverSocket) {
        io.to(receiverSocket).emit("messageUpdated", populated);
      }
    }

    message.pinned = true;
    message.pinnedBy = req.user._id;
    message.pinnedAt = new Date();

    await message.save();

    const updatedMessage = await Message.findById(message._id)
      .populate("replyTo");

    const senderSocket = onlineUsers.get(message.sender.toString());
    const receiverSocket = onlineUsers.get(message.receiver.toString());

    if (senderSocket) {
      io.to(senderSocket).emit("messageUpdated", updatedMessage);
    }

    if (receiverSocket) {
      io.to(receiverSocket).emit("messageUpdated", updatedMessage);
    }

    res.json(updatedMessage);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const unpinMessage = async (req, res) => {
  try {

    const { messageId } = req.params;

    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({
        message: "Message not found",
      });
    }

    if (!(await requesterCanAccessMessage(message, req.user._id))) {
      return res.status(403).json({ message: "Chat password required" });
    }

    message.pinned = false;
    message.pinnedBy = null;
    message.pinnedAt = null;

    await message.save();

    const updatedMessage = await Message.findById(message._id)
      .populate("replyTo");

    const senderSocket = onlineUsers.get(message.sender.toString());
    const receiverSocket = onlineUsers.get(message.receiver.toString());

    if (senderSocket) {
      io.to(senderSocket).emit("messageUpdated", updatedMessage);
    }

    if (receiverSocket) {
      io.to(receiverSocket).emit("messageUpdated", updatedMessage);
    }

    res.json(updatedMessage);

  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Server Error",
    });
  }
};
export const clearChat = async (req, res) => {
  try {
    const { receiverId } = req.params;

    const otherUser = await User.findById(receiverId).select("_id chatPasswordEnabled verifiedUsers");
    if (!otherUser) return res.status(404).json({ message: "User not found" });
    if (!canAccessChat(otherUser, req.user._id)) {
      return res.status(403).json({ message: "Chat password required" });
    }

    await Message.updateMany(
      {
        $or: [
          { sender: req.user._id, receiver: receiverId },
          { sender: receiverId, receiver: req.user._id },
        ],
      },
      {
        $addToSet: {
          deletedFor: req.user._id,
        },
      }
    );

    const messages = await Message.find({
      $or: [
        { sender: req.user._id, receiver: receiverId },
        { sender: receiverId, receiver: req.user._id },
      ],
    });

    for (const msg of messages) {
      if (
        msg.deletedFor.includes(msg.sender) &&
        msg.deletedFor.includes(msg.receiver)
      ) {
        await deleteCloudinaryAsset(msg);
        await msg.deleteOne();
      }
    }

    res.json({ message: "Chat cleared" });
  } catch (err) {
    res.status(500).json({ message: "Server Error" });
  }
};
