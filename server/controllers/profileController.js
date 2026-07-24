import User from "../models/User.js";
import cloudinary from "../config/cloudinary.js";

export const uploadProfilePicture = async (req, res) => {
    console.log("===== CLOUDINARY UPLOAD =====");
    console.log(req.file);

  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    // Delete previous Cloudinary image
    if (
      user.profilePic &&
      user.profilePic.includes("res.cloudinary.com")
    ) {
      try {
        const parts = user.profilePic.split("/");

        const uploadIndex = parts.findIndex(
          (part) => part === "upload"
        );
        console.log("Old URL:", user.profilePic);

        const publicId = parts
          .slice(uploadIndex + 2)
          .join("/")
          .replace(/\.[^/.]+$/, "");

        console.log("Deleting:", publicId);

        const result = await cloudinary.uploader.destroy(publicId);

        console.log("Cloudinary result:", result);
      } catch (err) {
        console.log("Old image not deleted:", err.message);
      }
    }

    user.profilePic = req.file.path;

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
