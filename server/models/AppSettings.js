import mongoose from "mongoose";

const appSettingsSchema = new mongoose.Schema({
  key: { type: String, unique: true, default: "global" },
  allowUserPasswordChange: { type: Boolean, default: false },
});

const AppSettings = mongoose.model("AppSettings", appSettingsSchema);
export default AppSettings;
