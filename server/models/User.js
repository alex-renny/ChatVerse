import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
    },

    profilePic: {
      type: String,
      default: "",
    },

    bio: {
      type: String,
      default: "Hey there! I'm using ReSender 💬",
    },

    status: {
      type: String,
      default: "Available"
    },

    lastSeen: {
      type: Date,
      default: Date.now,
    },

    isOnline: {
      type: Boolean,
      default: false,
    },

    pinnedChats: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

  },
  {
    timestamps: true,
  }
);

const User = mongoose.model("User", userSchema);

export default User;
