import express from "express";
import cors from "cors";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Test Route
app.get("/", (req, res) => {
  res.json({
    message: "Welcome to ChatVerse API 🚀",
  });
});
app.get("/about", (req, res) => {
  res.json({
    app: "ChatVerse",
    version: "1.0.0",
  });
});

export default app;