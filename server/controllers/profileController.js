import User from "../models/User.js";

export const uploadProfilePicture = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    user.profilePic = `/uploads/${req.file.filename}`;

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

        const { name, bio, status } = req.body;

        if (name !== undefined)
            user.name = name;

        if (bio !== undefined)
            user.bio = bio;

        if (status !== undefined)
            user.status = status;

        await user.save();

        res.json(user);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            message: "Update failed"
        });

    }
};