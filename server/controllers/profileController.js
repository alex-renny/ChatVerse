import User from "../models/User.js";
import cloudinary from "../config/cloudinary.js";
import bcrypt from "bcrypt";

const getPublicIdFromUrl = (url) => {
  try {
    const pathParts = new URL(url).pathname.split("/");
    const versionIndex = pathParts.findIndex((part) => /^v\d+$/.test(part));

    return versionIndex === -1
      ? ""
      : pathParts.slice(versionIndex + 1).join("/").replace(/\.[^/.]+$/, "");
  } catch {
    return "";
  }
};

const deleteProfilePicture = async (user) => {
  const publicId = user.profilePicPublicId || getPublicIdFromUrl(user.profilePic);

  if (publicId) {
    await cloudinary.uploader.destroy(publicId, { invalidate: true });
  }
};

export const uploadProfilePicture = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    if (user.profilePic) await deleteProfilePicture(user);

    user.profilePic = req.file.path;
    user.profilePicPublicId = req.file.path;

    await user.save();

    res.json(user);
  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Upload failed",
    });
  }
};

export const updateProfile = async (req, res) => {
    try {

        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        const { name, bio, status, profilePic } = req.body;

        if (name !== undefined)
            user.name = name;

        if (bio !== undefined)
            user.bio = bio;

        if (status !== undefined)
            user.status = status;

        if (profilePic === "" && user.profilePic) {
            await deleteProfilePicture(user);
            user.profilePicPublicId = "";
        }

        if (profilePic !== undefined)
            user.profilePic = profilePic;

        await user.save();

        res.json(user);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            message: "Update failed"
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

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.findById(req.user._id);

    user.chatPasswordEnabled = true;
    user.chatPassword = hashedPassword;

    await user.save();

    res.json({
      success: true,
      message: "Chat password saved",
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Unable to save chat password",
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
      message: "Chat password removed",
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Unable to remove chat password",
    });
  }
};

export const getChatPasswordStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate(
      "verifiedUsers",
      "name email profilePic"
    );

    res.json({
      enabled: user.chatPasswordEnabled,
      accessCount: user.verifiedUsers.length,
      verifiedUsers: user.verifiedUsers,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Unable to load chat password status",
    });
  }
};

export const removeVerifiedUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(req.user._id);

    user.verifiedUsers = user.verifiedUsers.filter(
      (id) => id.toString() !== userId
    );

    await user.save();

    res.json({
      success: true,
      accessCount: user.verifiedUsers.length,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      message: "Unable to remove access",
    });
  }
};