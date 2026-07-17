import User from "../models/User.js";
import Message from "../models/Message.js";

export const getConversationUsers = async (req, res) => {
  try {
    const userId = req.user._id;

    // Find every message where the logged-in user is sender or receiver
    const messages = await Message.find({
      $or: [
        { sender: userId },
        { receiver: userId },
      ],
    });

    // Collect the other user's IDs
    const userIds = new Set();

    messages.forEach((message) => {
      if (message.sender.toString() !== userId.toString()) {
        userIds.add(message.sender.toString());
      }

      if (message.receiver.toString() !== userId.toString()) {
        userIds.add(message.receiver.toString());
      }
    });

    const users = await User.find(
      {
        _id: {
          $in: [...userIds],
        },
      },
      "-password"
    );

    res.json(users);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const getUsers = async (req, res) => {
  try {
    const users = await User.find(
  {
    _id: { $ne: req.user._id },
  },
  "-password"
);

    res.status(200).json(users);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server Error",
    });
  }
};