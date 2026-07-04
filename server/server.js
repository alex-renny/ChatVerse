import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";

import userRoutes from "./routes/userRoutes.js";

import connectDB from "./config/db.js";
import { createServer } from "http";
import { Server } from "socket.io";
import messageRoutes from "./routes/messageRoutes.js";

dotenv.config();

connectDB();

const app = express();

const server = createServer(app);

const io = new Server(server, {
  cors: {
    origin: "http://localhost:5173",
    methods: ["GET", "POST"],
  },
});
const onlineUsers = new Map();  

io.on("connection", (socket) => {
  console.log("🟢 Connected:", socket.id);

  socket.on("join", (userId) => {
    onlineUsers.set(userId, socket.id);

    console.log("User Joined:", userId);

    io.emit("onlineUsers", [...onlineUsers.keys()]);
  });

  socket.on("disconnect", () => {
    for (const [userId, socketId] of onlineUsers.entries()) {
      if (socketId === socket.id) {
        onlineUsers.delete(userId);
        break;
      }
    }

    io.emit("onlineUsers", [...onlineUsers.keys()]);

    console.log("🔴 Disconnected:", socket.id);
  });
});

app.use(cors());
app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/messages", messageRoutes);

app.get("/", (req, res) => {
  res.send("🚀 ChatVerse API Running");
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});