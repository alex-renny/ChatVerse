import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import cloudinary from "./cloudinary.js";

const storage = new CloudinaryStorage({
  cloudinary,
  params: (req, file) => ({
    folder: "chatverse/messages",
    // Cloudinary serves audio through the `video` resource type.  Using
    // `auto` here can classify recorded WebM audio as raw and reject it.
    resource_type: file.mimetype.startsWith("audio/") || file.mimetype.startsWith("video/")
      ? "video"
      : file.mimetype.startsWith("image/")
        ? "image"
        : "raw",
  }),
});

export default multer({ storage });
