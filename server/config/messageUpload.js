import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import cloudinary from "./cloudinary.js";

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    // `auto` lets Cloudinary store images as images and every other
    // attachment (PDF, DOCX, ZIP, etc.) as a raw asset.
    folder: "chatverse/messages",
    resource_type: "auto",
  },
});

export default multer({ storage });
