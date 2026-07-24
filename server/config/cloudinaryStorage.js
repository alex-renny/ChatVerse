import { CloudinaryStorage } from "multer-storage-cloudinary";
import multer from "multer";
import cloudinary from "./cloudinary.js";

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "chatverse",
    allowed_formats: ["jpg", "jpeg", "png", "gif", "webp"],
  },
});

export default multer({ storage });