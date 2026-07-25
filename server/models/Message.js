import mongoose from "mongoose";

const messageSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    text: {
      type: String,
      trim: true,
    },

    delivered: {
      type: Boolean,
      default: false,
    },

    seen: {
      type: Boolean,
      default: false,
    },

    attachment: {
      url: String,
      name: String,
      mimeType: String,
      size: Number,
      cloudinaryPublicId: String,
      resourceType: String,
    },
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
    },
    reactions: [
    {
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      emoji: String,
    },
  ],

    deletedFor: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    deletedForEveryone: {
      type: Boolean,
      default: false,
    },

    deletedAt: Date,
    pinned: {
      type: Boolean,
      default: false,
    },

    pinnedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    pinnedAt: Date,

    image: {
        type: String,
        default: "",
    },

    imagePublicId: {
      type: String,
      default: "",
    },

    imageResourceType: {
      type: String,
      default: "image",
    },

    file: {
        type: String,
        default: "",
    },

    fileName: {
        type: String,
        default: "",
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model("Message", messageSchema);
