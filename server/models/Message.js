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
    image: {
      type: String,
      default: "",
    },
    attachment: {
      url: String,
      name: String,
      mimeType: String,
      size: Number,
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
  },
  {
    timestamps: true,
  }
);

export default mongoose.model("Message", messageSchema);
