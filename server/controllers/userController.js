import User from "../models/User.js";
import Message from "../models/Message.js";

export const getConversationUsers = async (req, res) => {
  try {
    const userId = req.user._id;

    // Find all conversations involving the logged-in user
    const messages = await Message.find({
      $or: [
        { sender: userId },
        { receiver: userId },
      ],
    });

    // Get unique user IDs
    const userIds = new Set();

    messages.forEach((message) => {
      if (message.sender.toString() !== userId.toString()) {
        userIds.add(message.sender.toString());
      }

      if (message.receiver.toString() !== userId.toString()) {
        userIds.add(message.receiver.toString());
      }
    });

    const currentUser = await User.findById(userId).select("pinnedChats");
    const pinnedChatIds = new Set(
      currentUser.pinnedChats.map((chatId) => chatId.toString())
    );

    const users = await User.find(
      {
        _id: { $in: [...userIds] },
      },
      "-password"
    );

    res.json(
      users
        .map((user) => ({
          ...user.toObject(),
          isPinned: pinnedChatIds.has(user._id.toString()),
        }))
        .sort((a, b) => Number(b.isPinned) - Number(a.isPinned))
    );

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

export const togglePinnedChat = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(req.user._id);

    const isPinned = user.pinnedChats.some(
      (chatId) => chatId.toString() === userId
    );

    user.pinnedChats = isPinned
      ? user.pinnedChats.filter((chatId) => chatId.toString() !== userId)
      : [...user.pinnedChats, userId];

    await user.save();
    res.json({ userId, pinned: !isPinned });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Unable to update pinned chat" });
  }
};
