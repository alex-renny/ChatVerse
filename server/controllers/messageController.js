import Message from "../models/Message.js";
import { io, onlineUsers } from "../server.js";

// Send a message
export const sendMessage = async (req, res) => {
  try {
    const { receiver, text } = req.body;

    const message = await Message.create({
      sender: req.user._id,
      receiver,
      text,
    });

    // If receiver is online, send instantly
    const receiverSocketId = onlineUsers.get(receiver);

    if (receiverSocketId) {
      io.to(receiverSocketId).emit("receiveMessage", message);
      console.log("📨 Sent instantly to:", receiver);
    } else {
      console.log("📴 Receiver offline");
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
    }).sort({ createdAt: 1 });

    res.json(messages);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};