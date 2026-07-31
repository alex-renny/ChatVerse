import User from "../models/User.js";
import Message from "../models/Message.js";
import bcrypt from "bcrypt";

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

export const saveChatBackground = async (req, res) => {
  try {
    const { userId } = req.params;
    const { background } = req.body;

    const user = await User.findById(req.user._id);

    user.chatBackgrounds.set(userId, background);

    await user.save();

    res.json({
      success: true,
      background,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Unable to save background",
    });
  }
};

export const getChatBackground = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(req.user._id);

    const background =
      user.chatBackgrounds.get(userId) || "";

    res.json({
      background,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Unable to load background",
    });
  }
};

export const setChatPassword = async (req, res) => {
  try {
    const { password } = req.body;

    if (!password || password.length < 4) {
      return res.status(400).json({
        message: "Password must be at least 4 characters",
      });
    }

    const hashed = await bcrypt.hash(password, 10);

    const user = await User.findById(req.user._id);

    user.chatPasswordEnabled = true;
    user.chatPassword = hashed;

    await user.save();

    res.json({
      success: true,
      message: "Chat password saved",
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const removeChatPassword = async (req, res) => {
  try {

    const user = await User.findById(req.user._id);

    user.chatPasswordEnabled = false;
    user.chatPassword = "";
    user.verifiedUsers = [];

    await user.save();

    res.json({
      success: true,
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const isChatPasswordEnabled = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const requesterId = req.user._id.toString();
    const verified = !user.chatPasswordEnabled || user.verifiedUsers.some(
      (id) => id.toString() === requesterId
    );

    res.json({
      enabled: user.chatPasswordEnabled,
      verified,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Server Error",
    });
  }
};

export const verifyChatPassword = async (req, res) => {

  try {

    const { userId, password } = req.body;

    const receiver = await User.findById(userId);

    if (!receiver.chatPasswordEnabled) {
      return res.json({
        success: true,
      });
    }

    const ok = await bcrypt.compare(
      password,
      receiver.chatPassword
    );

    if (!ok) {
      return res.status(401).json({
        message: "Wrong password",
      });
    }

    if (
      !receiver.verifiedUsers.some(
        (id) => id.toString() === req.user._id.toString()
      )
    ) {
      receiver.verifiedUsers.push(req.user._id);
      await receiver.save();
    }

    res.json({
      success: true,
    });

  } catch (err) {

    console.error(err);

    res.status(500).json({
      message: "Server Error",
    });

  }

};