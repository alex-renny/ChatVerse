import bcrypt from "bcrypt";
import User from "../models/User.js";
import AppSettings from "../models/AppSettings.js";

export const changeOwnPassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (typeof currentPassword !== "string" || !currentPassword ||
        typeof newPassword !== "string" || newPassword.length < 6) {
      return res.status(400).json({ message: "Enter your current password and a new password of at least 6 characters" });
    }

    const settings = await AppSettings.findOne({ key: "global" }).lean();
    if (settings?.allowUserPasswordChange !== true) {
      return res.status(403).json({ message: "Password changes are disabled by the admin" });
    }

    const user = await User.findById(req.user._id).select("password passwordChangeCount +pendingPasswordChangeHash");
    if (!user || !(await bcrypt.compare(currentPassword, user.password))) {
      return res.status(401).json({ message: "Current password is incorrect" });
    }
    if (await bcrypt.compare(newPassword, user.password)) {
      return res.status(400).json({ message: "Choose a password different from your current password" });
    }
    if (user.pendingPasswordChangeHash) {
      return res.status(409).json({ message: "A password change request is already waiting for admin approval" });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    if ((user.passwordChangeCount || 0) === 0) {
      user.password = newHash;
      user.passwordChangeCount = 1;
      await user.save();
      return res.json({ success: true, approvalRequired: false, message: "Password changed successfully" });
    }

    user.pendingPasswordChangeHash = newHash;
    user.passwordChangeRequestedAt = new Date();
    await user.save();
    return res.status(202).json({
      success: true,
      approvalRequired: true,
      message: "Your password change request was sent to the admin",
    });
  } catch (error) {
    console.error("Password change error:", error.message);
    return res.status(500).json({ message: "Could not process the password change" });
  }
};
