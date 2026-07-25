import User from "../models/User.js";
import cloudinary from "../config/cloudinary.js";

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
    user.profilePicPublicId = req.file.filename;

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
