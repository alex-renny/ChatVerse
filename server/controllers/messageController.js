import Message from "../models/Message.js";
import { io, onlineUsers } from "../server.js";

// Send a message
export const sendMessage = async (req, res) => {
  try {
    const { receiver, text, replyTo } = req.body;

    const uploadUrl = req.file ? `/uploads/${req.file.filename}` : "";
    const image = req.file?.mimetype.startsWith("image/") ? uploadUrl : "";
    const attachment = req.file && !image
      ? {
          url: uploadUrl,
          name: req.file.originalname,
          mimeType: req.file.mimetype,
          size: req.file.size,
        }
      : undefined;

    const messageData = {
  sender: req.user._id,
  receiver,
  text,
  image,
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
  const receiverSocket = onlineUsers.get(message.receiver.toString());
  const senderSocket = onlineUsers.get(message.sender.toString());

  if (receiverSocket) {
    io.to(receiverSocket).emit("messageReaction", message);
  }

  if (senderSocket) {
    io.to(senderSocket).emit("messageReaction", message);
  }

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

    const messages = await Message.find({
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
})
.populate("replyTo")
.sort({ createdAt: 1 });

    res.json(messages);

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

// Delete a message
export const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({
        message: "Message not found",
      });
    }

    // Either participant in the conversation can delete a message.
    if (
      message.sender.toString() !== req.user._id.toString() &&
      message.receiver.toString() !== req.user._id.toString()
    ) {
      return res.status(403).json({
        message: "Not authorized",
      });
    }

    await message.deleteOne();

    res.json({
      message: "Message deleted successfully",
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
