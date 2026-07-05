import Message from "../models/Message.js";
import { io, onlineUsers } from "../server.js";

// Send a message
export const sendMessage = async (req, res) => {
  try {
    const { receiver, text, replyTo } = req.body;

    const image = req.file
      ? `/uploads/${req.file.filename}`
      : "";

    const messageData = {
  sender: req.user._id,
  receiver,
  text,
  image,
};

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

    // Only the sender can delete their own message
    if (message.sender.toString() !== req.user._id.toString()) {
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